output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "demo_app_repo_url" {
  value = aws_ecr_repository.app.repository_url
}