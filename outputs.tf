output "alb_url" {
    # reference the outputs.tf name
  value = module.ecs.alb_dns_name
}

output "demo_app_repo_url" {
  value = module.ecs.demo_app_repo_url
}