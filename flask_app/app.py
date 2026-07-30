import os
import sys
import uuid
import datetime
import logging
import boto3
from flask import Flask, request, redirect, url_for, render_template, jsonify

app = Flask(__name__)

# ------------------------------------------------------------------------------
# Logging Configuration
# ------------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s in %(module)s [%(process)d]: %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout)  # Required for Docker/CloudWatch streaming
    ]
)
logger = logging.getLogger("compie_app")

# ------------------------------------------------------------------------------
# AWS & DynamoDB Configuration
# ------------------------------------------------------------------------------
AWS_REGION = os.environ.get("AWS_REGION", "us-east-1")
TABLE_NAME = os.environ.get("DYNAMODB_TABLE", "compie_reviews")

logger.info(f"Initializing app with AWS Region: {AWS_REGION}, DynamoDB Table: {TABLE_NAME}")

try:
    dynamodb = boto3.resource("dynamodb", region_name=AWS_REGION)
    table = dynamodb.Table(TABLE_NAME)
except Exception as e:
    logger.error(f"Failed to initialize DynamoDB resource: {str(e)}", exc_info=True)

# ------------------------------------------------------------------------------
# Middleware / Request Logging
# ------------------------------------------------------------------------------
@app.before_request
def log_request_info():
    # Skip noisy logs for ALB health check calls
    if request.path != "/health":
        logger.info(f"HTTP {request.method} {request.path} from {request.remote_addr}")

# ------------------------------------------------------------------------------
# Routes
# ------------------------------------------------------------------------------
@app.route("/", methods=["GET"])
def index():
    try:
        response = table.scan()
        reviews = response.get("Items", [])
        reviews.sort(key=lambda x: x.get("created_at", ""), reverse=True)
        logger.info(f"Successfully retrieved {len(reviews)} reviews from DynamoDB.")
    except Exception as e:
        logger.error(f"Error reading from DynamoDB table '{TABLE_NAME}': {str(e)}", exc_info=True)
        reviews = []

    return render_template("index.html", reviews=reviews)

@app.route("/review", methods=["POST"])
def add_review():
    reviewer_name = request.form.get("reviewer_name")
    content = request.form.get("content")

    if reviewer_name and content:
        review_id = str(uuid.uuid4())
        item = {
            "review_id": review_id,
            "reviewer_name": reviewer_name,
            "content": content,
            "created_at": datetime.datetime.now(datetime.timezone.utc).isoformat()
        }
        try:
            table.put_item(Item=item)
            logger.info(f"Successfully saved review ID {review_id} by '{reviewer_name}'")
        except Exception as e:
            logger.error(f"Failed writing review ID {review_id} to DynamoDB: {str(e)}", exc_info=True)
    else:
        logger.warning(f"Submission rejected: Missing required fields (reviewer_name or content) from {request.remote_addr}")

    return redirect(url_for("index"))

@app.route("/health", methods=["GET"])
def health():
    """Health check endpoint used by the Application Load Balancer."""
    try:
        table.load()
        return jsonify({"status": "healthy", "database": "connected", "table": TABLE_NAME}), 200
    except Exception as e:
        logger.error(f"Health check failed on DynamoDB table '{TABLE_NAME}': {str(e)}")
        return jsonify({"status": "unhealthy", "database_error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)