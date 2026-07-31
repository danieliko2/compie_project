# Security Group for Public ALB
resource "aws_security_group" "alb_sg" {
  name        = "${var.environment}-alb-sg"
  description = "Allow public inbound traffic to ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "HTTP from Internet"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description = "Allow all outbound traffic to private instances"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.environment}-alb-sg" }
}

# Security Group for ASG EC2 Instances
resource "aws_security_group" "app_sg" {
  name        = "${var.environment}-app-sg"
  description = "Allow traffic to container port strictly from ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "HTTP container port from ALB SG only"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Allow outbound traffic for image pulls and updates via NAT"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.environment}-app-sg" }
}