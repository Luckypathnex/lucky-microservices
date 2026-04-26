output "log_group_application" {
  description = "Application log group name"
  value       = aws_cloudwatch_log_group.application.name
}

output "log_group_workers" {
  description = "Workers log group name"
  value       = aws_cloudwatch_log_group.workers.name
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}