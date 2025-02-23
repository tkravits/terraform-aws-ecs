output "alb_url" {
    # reference the outputs.tf name
  value = module.ecs.alb_dns_name
}
