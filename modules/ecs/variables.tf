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

variable "ecs_launch_type" {
  description = "Choose between 'EC2' and 'FARGATE' for ECS deployment"
  type        = string
  default     = "FARGATE"
  validation {
    condition     = contains(["EC2", "FARGATE"], var.ecs_launch_type)
    error_message = "Valid values are 'EC2' or 'FARGATE'"
  }
}
