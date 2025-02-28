terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "5.17.0" }
  }
}

provider "aws" {
  # this profile uses 'terraform' which was created using AWS IAM identity center
  # login using aws sso login --profile '<name>' which in this case is called 'terraform'
  profile = "terraform"
  region  = "us-east-1"
}

module "vpc" {
  source = "./modules/networking"
}

module "ecs" {
  source     = "./modules/ecs"
  vpc_id     = module.vpc.aws_vpc.id
  cidr_block = module.vpc.aws_vpc.cidr_block
  subnets    = module.vpc.aws_subnets
  ecs_launch_type = var.ecs_launch_type
}