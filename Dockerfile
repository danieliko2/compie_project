# 1. Use an official, lightweight Python image
FROM python:3.11-slim

# 2. Set working directory
WORKDIR /app

# 3. Copy dependencies first (takes advantage of Docker layer caching)
COPY ./flask_app/requirements.txt .

# 4. Install dependencies into the container's environment
RUN pip install --no-cache-dir -r requirements.txt

# 5. Copy the rest of the application code
COPY ./flask_app/ .

# 6. Expose the application port
EXPOSE 5000

# 7. Run using a production WSGI server (e.g., Gunicorn)
CMD ["python", "app.py"]