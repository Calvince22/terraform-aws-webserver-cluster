output "alb_dns_name" {
  value       = aws_lb.example.dns_name
  description = "ALB DNS"
}

output "asg_name" {
  value       = aws_autoscaling_group.example.name
  description = "ASG name"
}

output "cpu_alarm_name" {
  value = local.enable_monitoring ? aws_cloudwatch_metric_alarm.cpu[0].alarm_name : null
}