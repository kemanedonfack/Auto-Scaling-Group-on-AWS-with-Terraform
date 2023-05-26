output "lb_endpoint" {
  value = aws_lb.terramino.dns_name
}

output "application_endpoint" {
  value = aws_lb.terramino.dns_name
}

output "asg_name" {
  value = aws_autoscaling_group.terramino.name
}