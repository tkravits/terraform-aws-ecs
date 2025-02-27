variable "ecs_launch_type" {
  description = "Choose between 'EC2' and 'FARGATE' for ECS deployment"
  type        = string
  default     = "FARGATE"
  validation {
    condition     = contains(["EC2", "FARGATE"], var.ecs_launch_type)
    error_message = "Valid values are 'EC2' or 'FARGATE'"
  }
}
