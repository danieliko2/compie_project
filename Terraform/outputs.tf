output "alb_dns_name" {
  description = "Public DNS URL of the Application Load Balancer"
  value       = aws_lb.public_alb.dns_name
}

output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}