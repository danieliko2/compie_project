import os
import uuid
import datetime
import boto3
from flask import Flask, request, redirect, url_for, render_template, jsonify

app = Flask(__name__)

# AWS Region & DynamoDB Resource setup using IAM Role credentials
AWS_REGION = os.environ.get("AWS_REGION", "us-east-1")
TABLE_NAME = os.environ.get("DYNAMODB_TABLE", "compie_reviews")

dynamodb = boto3.resource("dynamodb", region_name=AWS_REGION)
table = dynamodb.Table(TABLE_NAME)

@app.route("/", methods=["GET"])
def index():
    try:
        # Fetch all records from DynamoDB
        response = table.scan()
        reviews = response.get("Items", [])
        # Sort by creation date descending
        reviews.sort(key=lambda x: x.get("created_at", ""), reverse=True)
    except Exception as e:
        print(f"Error reading from DynamoDB: {e}")
        reviews = []

    # Renders templates/index.html cleanly
    return render_template("index.html", reviews=reviews)

@app.route("/review", methods=["POST"])
def add_review():
    reviewer_name = request.form.get("reviewer_name")
    content = request.form.get("content")

    if reviewer_name and content:
        item = {
            "review_id": str(uuid.uuid4()),
            "reviewer_name": reviewer_name,
            "content": content,
            "created_at": datetime.datetime.utcnow().isoformat()
        }
        try:
            table.put_item(Item=item)
        except Exception as e:
            print(f"Error writing to DynamoDB: {e}")

    return redirect(url_for("index"))

@app.route("/health", methods=["GET"])
def health():
    """Health check endpoint used by the Application Load Balancer."""
    try:
        table.load()
        return jsonify({"status": "healthy", "database": "connected", "table": TABLE_NAME}), 200
    except Exception as e:
        return jsonify({"status": "unhealthy", "database_error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)