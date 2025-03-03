output "ecs_cluster" {
    value = aws_ecs_cluster.main
}

output "alb_target_group" {
    value = aws_lb_target_group.app
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "demo_app_repo_url" {
  value = aws_ecr_repository.app.repository_url
}

output "ecs_node_sg" {
  value = aws_security_group.ecs_node_sg
}

output "ecr_url" {
  value = aws_ecr_repository.app.repository_url
  
}

output "security_group_ecs_task" {
  value = aws_security_group.ecs_task
}