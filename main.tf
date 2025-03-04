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
  depends_on      = [module.vpc]
  source          = "./modules/ecs"
  vpc_id          = module.vpc.aws_vpc.id
  cidr_block      = module.vpc.aws_vpc.cidr_block
  subnets         = module.vpc.aws_subnets
  ecs_launch_type = var.ecs_launch_type
}

module "cloudwatch" {
  source = "./modules/cloudwatch"
}
module "ecs_ec2" {
  depends_on              = [module.ecs]
  ecs_cluster             = module.ecs.ecs_cluster
  count                   = var.ecs_launch_type == "EC2" ? 1 : 0
  source                  = "./modules/ecs_ec2"
  alb_target_group        = module.ecs.alb_target_group
  ecr_url                 = module.ecs.ecr_url
  ecs_node_sg             = module.ecs.ecs_node_sg
  security_group_ecs_task = module.ecs.security_group_ecs_task
  cloudwatch_logs_name    = module.cloudwatch.ecs_cloudwatch_logs_name
  vpc_id                  = module.vpc.aws_vpc.id
  # cidr_block              = module.vpc.aws_vpc.cidr_block
  subnets                 = module.vpc.aws_subnets
  ecs_launch_type         = var.ecs_launch_type
}

module "ecs_fargate" {
  depends_on              = [module.ecs]
  ecs_cluster             = module.ecs.ecs_cluster
  alb_target_group        = module.ecs.alb_target_group
  count                   = var.ecs_launch_type == "FARGATE" ? 1 : 0
  source                  = "./modules/ecs_fargate"
  cloudwatch_logs_name    = module.cloudwatch.ecs_cloudwatch_logs_name
  security_group_ecs_task = module.ecs.security_group_ecs_task
  ecr_url                 = module.ecs.ecr_url
  vpc_id                  = module.vpc.aws_vpc.id
  # cidr_block              = module.vpc.aws_vpc.cidr_block
  subnets                 = module.vpc.aws_subnets
  ecs_launch_type         = var.ecs_launch_type
}