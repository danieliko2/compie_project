# 1. Fetch Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

# 2. EC2 Launch Template Configuration
resource "aws_launch_template" "app_lt" {
  name_prefix   = "${var.environment}-lt-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_profile.arn
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.app_sg.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y docker aws-cli jq
              systemctl enable --now docker

              # Fetch parameters from SSM Parameter Store and create a .env file
              mkdir -p /etc/app
              aws ssm get-parameters-by-path \
                --path "/${var.environment}/compie_app/" \
                --with-decryption \
                --region ${var.aws_region} \
                --query "Parameters[*].[Name,Value]" \
                --output text | awk '{split($1,a,"/"); print a[length(a)] "=" $2}' > /etc/app/env.file

              # Extract ECR registry URL
              REGISTRY_URL=$(echo "${var.container_image}" | cut -d'/' -f1)

              # Authenticate Docker against Amazon ECR
              aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin $REGISTRY_URL

              # Pull and run container, passing SSM variables automatically!
              docker pull ${var.container_image}
              docker run -d \
                --restart=always \
                --env-file /etc/app/env.file \
                -p ${var.container_port}:${var.container_port} \
                ${var.container_image}
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.environment}-asg-instance"
      Environment = var.environment
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 3. Auto Scaling Group Configuration
resource "aws_autoscaling_group" "app_asg" {
  name_prefix         = "${var.environment}-asg-"
  vpc_zone_identifier = module.vpc.private_subnets
  target_group_arns   = [aws_lb_target_group.app_tg.arn]

  min_size         = 1
  desired_capacity = 2
  max_size         = 3

  force_delete              = true
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-asg-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}