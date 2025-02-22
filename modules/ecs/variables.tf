variable "vpc_id" {
  description = "The ID of the VPC where ECS instances will be deployed"
  type        = string
}
variable "cidr_block" {
  description = "The IPv4 CIDR block for the VPC"
  type        = string
}
# variable "subnet_id" {
#   description = "the id for the subnet"
#   type = string
# }

variable "subnets" {
  description = "a list of subnets"
  type = list(object({
    id   = string
  }))
}