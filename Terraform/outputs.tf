output "alb_dns_name" {
  description = "Public URL of the Application Load Balancer"
  value       = aws_lb.public_alb.dns_name
}