variable "vpc_id" {
  description = "The ID of the VPC where ECS instances will be deployed"
  type        = string
}
variable "cidr_block" {
  description = "The IPv4 CIDR block for the VPC"
  type        = string
}
variable "subnets" {
  description = "a list of subnets"
  type = list(object({
    id   = string
  }))
}
variable "ecs_cluster" {
  description = "Information for the ECS cluster"
  type        = object({
    name = string
    id = string
  })
}

variable "alb_target_group" {
  description = "ARN of the ALB Target Group"
  type        = object({
    name = string
    arn = string
  })
}

variable "cloudwatch_logs_name" {
  description = "CloudWatch log group for ECS tasks"
  type        = string
}

variable "ecs_node_sg" {
  description = "Security Group ID for ECS nodes"
    type        = object({
    name = string
    id = string
  })
}

variable "ecr_url" {
  description = "ECR repository URI for the application image"
  type        = string
}

variable "security_group_ecs_task" {
  description = "Security Group ID for ECS tasks"
  type        = object({
    name = string
    id = string
  })
}

variable "ecs_launch_type" {
  description = "Choose between 'EC2' and 'FARGATE' for ECS deployment"
  type        = string
  validation {
    condition     = contains(["EC2", "FARGATE"], var.ecs_launch_type)
    error_message = "Valid values are 'EC2' or 'FARGATE'"
  }
}
