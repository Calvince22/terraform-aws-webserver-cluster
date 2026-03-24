output "alb_dns_name" {
  value       = aws_lb.example.dns_name
  description = "ALB DNS"
}

output "asg_name" {
  value       = aws_autoscaling_group.example.name
  description = "ASG name"
}


