resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/eks/${var.cluster_name}/application"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "workers" {
  name              = "/aws/eks/${var.cluster_name}/workers"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"

  tags = var.tags
}

resource "aws_sns_topic_subscription" "alerts_email" {
  count = var.alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "eks_node_cpu" {
  alarm_name          = "${var.cluster_name}-high-cpu-nodes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when EKS node CPU exceeds 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  tags = var.tags
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EKS", "cluster_node_count", { stat = "Average" }],
            [".", "cluster_cpu_utilization", { stat = "Average" }],
            [".", "cluster_memory_utilization", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "EKS Cluster Metrics"
        }
      }
    ]
  })
}