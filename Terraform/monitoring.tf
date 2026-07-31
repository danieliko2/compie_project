# 1. CloudWatch Log Group for Application Traceability
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/container/compie_app"
  retention_in_days = 7
}

# 2. SNS Topic for Infrastructure Alerts
resource "aws_sns_topic" "alerts" {
  name = "compie-app-infrastructure-alerts"
}

# 3. Placeholder Webhook Endpoint Subscription
resource "aws_sns_topic_subscription" "webhook_endpoint" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "https"
  endpoint  = "https://webhook.site/placeholder-endpoint" # Placeholder endpoint as requested
}

# 4. CloudWatch Metric Alarm: Unhealthy ALB Targets
resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "production-unhealthy-targets"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    TargetGroup  = aws_lb_target_group.app_tg.arn_suffix
    LoadBalancer = aws_lb.public_alb.arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}