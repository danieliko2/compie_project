variable "aws_region" {
  type        = string
  description = "AWS Region to deploy resources"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Environment name tag"
  default     = "production"
}

variable "instance_type" {
  type        = string
  description = "EC2 Instance Type"
  default     = "t3.micro"
}

variable "container_image" {
  type        = string
  description = "Docker image URI in Amazon ECR"
  default     = "367425865577.dkr.ecr.us-east-1.amazonaws.com/daniel_dev/compie_app:latest"
}

variable "container_port" {
  type        = number
  description = "Port exposed by the Docker container"
  default     = 5000
}

variable "health_check_path" {
  type        = string
  description = "Health check path for ALB Target Group"
  default     = "/"
}

variable "app_username" {
  type        = string
  description = "Default admin username for the application"
  default     = "admin"
}

variable "app_password" {
  type        = string
  description = "Default admin password for the application"
  default     = "InitialSecurePassword123!"
  sensitive   = true
}