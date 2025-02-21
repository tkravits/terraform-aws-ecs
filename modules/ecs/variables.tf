variable "vpc_id" {
  description = "The ID of the VPC where ECS instances will be deployed"
  type        = string
}
variable "cidr_block" {
  description = "The IPv4 CIDR block for the VPC"
  type        = string
}
variable "subnet" {
}