


# --- ECS Node Role ---
# Generates an IAM policy document in JSON format. This will be attached to 
# IAM roles under the assume_role_policy. Role Policies need to be in JSON format so instead
# of creating a json every time, you can use this and attach it to a role
# this only works for EC2. EC2 needs to assume a role in order to act as an ECS node

# TODO change the service to fargate
data "aws_iam_policy_document" "ecs_node_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# creates the IAM role and grants EC2 permissions to run ECS nodes using the role policy from above
# AWS does not automatically do this so it needs to be specified
resource "aws_iam_role" "ecs_node_role" {
  name_prefix        = "demo-ecs-node-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_node_doc.json
}

# # EC2 instance wouldn’t be able to join the ECS cluster or pull container images without this specific policy ARN (service role)
# resource "aws_iam_role_policy_attachment" "ecs_node_role_policy" {
#   count      = var.ecs_launch_type == "EC2" ? 1 : 0
#   role       = aws_iam_role.ecs_node_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
# }

resource "aws_iam_role_policy_attachment" "ecs_node_role_policy_fargate" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.ecs_node_role.name
}
# EC2 instances do not directly assume IAM roles—they need an instance profile. 
# The instance profile acts as a bridge to connect the IAM role to the instance
# resource "aws_iam_instance_profile" "ecs_node" {
#   name_prefix = "demo-ecs-node-profile"
#   path        = "/ecs/instance/"
#   role        = aws_iam_role.ecs_node_role.name
# }


# --- ECS Launch Template ---
# Retrieves the latest Amazon ECS-Optimized AMI for Amazon Linux 2 from AWS Systems Manager (SSM)
# data "aws_ssm_parameter" "ecs_node_ami" {
#   name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
# }
# creates the ec2 instances based on the configuration of the launch template and attaches them to the ECS node
# resource "aws_launch_template" "ecs_ec2" {
#   count                 = var.ecs_launch_type == "EC2" ? 1 : 0
#   name_prefix            = "demo-ecs-ec2-"
#   image_id               = data.aws_ssm_parameter.ecs_node_ami.value
#   instance_type          = "t2.micro"
#   vpc_security_group_ids = [aws_security_group.ecs_node_sg.id]
#   # uses the same instance profile and attaches it to the EC2 instance
#   iam_instance_profile { arn = aws_iam_instance_profile.ecs_node.arn }
#   # enables cloud monitoring
#   monitoring { enabled = true }

#   # runs a script that connects the EC2 instance to the ECS cluster created
#   user_data = base64encode(<<-EOF
#       #!/bin/bash
#       echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config;
#     EOF
#   )
# }

# --- ECS ASG ---
# creates autoscaling group that will have a min of 2 instances and a max of 8
# uses health checks but will terminate an instance immediately if it is unhealthy
# resource "aws_autoscaling_group" "ecs" {
#   count                 = var.ecs_launch_type == "EC2" ? 1 : 0
#   name_prefix               = "demo-ecs-asg-"
#   vpc_zone_identifier       = var.subnets[*].id
#   min_size                  = 2
#   max_size                  = 8
#   health_check_grace_period = 0
#   health_check_type         = "EC2"
#   # instances can be terminated when scaled down
#   protect_from_scale_in     = false

#   # use the latest version of the EC2 instances set up
#   launch_template {
#     id      = aws_launch_template.ecs_ec2[0].id
#     version = "$Latest"
#   }

#   tag {
#     key                 = "Name"
#     value               = "demo-ecs-cluster"
#     propagate_at_launch = true
#   }

#   tag {
#     key                 = "AmazonECSManaged"
#     value               = ""
#     propagate_at_launch = true
#   }
# }

# --- ECS Capacity Provider ---
# so now that EC2 can scale, we need to get ECS to scale
# this links the autoscaling group allowing ECS tasks to scale
# resource "aws_ecs_capacity_provider" "main" {
#   count                 = var.ecs_launch_type == "EC2" ? 1 : 0
#   name = "demo-ecs-ec2"

#   auto_scaling_group_provider {
#     auto_scaling_group_arn         = aws_autoscaling_group.ecs[0].arn
#     managed_termination_protection = "DISABLED"

#     managed_scaling {
#       maximum_scaling_step_size = 2
#       minimum_scaling_step_size = 1
#       status                    = "ENABLED"
#       target_capacity           = 100
#     }
#   }
# }

# # creates a scaling strategy for the ECS tasks
# resource "aws_ecs_cluster_capacity_providers" "main" {
#   for_each = var.ecs_launch_type == "EC2" ? toset(["enabled"]) : toset([])

#   cluster_name       = aws_ecs_cluster.main.name
#   capacity_providers = [aws_ecs_capacity_provider.main[0].name]

#   default_capacity_provider_strategy {
#     capacity_provider = aws_ecs_capacity_provider.main[0].name
#     base              = 1
#     weight            = 100
#   }
# }

# --- ECS Task Role ---
# creates the policy document for ECS tasks so they can assume the IAM role.
# This will be assigned to the ecs_task_role to make it more readable that
# the IAM is assuming this role
data "aws_iam_policy_document" "ecs_task_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# creates the ECS task role and uses the above policy
resource "aws_iam_role" "ecs_task_role" {
  name_prefix        = "demo-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
}
# creates the ECS execution role
resource "aws_iam_role" "ecs_exec_role" {
  name_prefix        = "demo-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
}
# AWS has a specific role found in the policy ARN, create this policy attachment and 
# attach it to the ecs_exec role
resource "aws_iam_role_policy_attachment" "ecs_exec_role_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- ECS Task Definition ---
# Creates the task definition that tells ECS how to run the image
resource "aws_ecs_task_definition" "app" {
  family             = "demo-app"
  # role for the running container
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  # role for the ecs agent which pulls the image
  execution_role_arn = aws_iam_role.ecs_exec_role.arn
  # using AWS VPC networking which means an EIP gets attached
  network_mode       = "awsvpc"
  # CPU and memory limits
  cpu                = 256
  memory             = 512
  requires_compatibilities = ["FARGATE"]


  # pulls the latest image from the elastic container registry
  container_definitions = jsonencode([{
    name         = "app",
    image        = "${var.ecr.repository_url}:latest",
    # if the container fails, restart
    essential    = true,
    portMappings = [{ containerPort = 80, hostPort = 80 }],
    # add environment variables to the container
    environment = [
      { name = "EXAMPLE", value = "example" }
    ]

    # configures cloudwatch logs
    logConfiguration = {
      logDriver = "awslogs",
      options = {
        "awslogs-region"        = "us-east-1",
        "awslogs-group"         = var.cloudwatch_logs.ecs.name,
        "awslogs-stream-prefix" = "app"
      }
    },
  }])
}

# --- ECS Service ---





# Creates the ECS service which orchestrates the desired number of tasks is running at all times
# this is looking to have 2 tasks running at all times
# resource "aws_ecs_service" "app_ec2" {
#   count           = var.ecs_launch_type == "EC2" ? 1 : 0
#   name            = "app"
#   cluster         = aws_ecs_cluster.main.id
#   task_definition = aws_ecs_task_definition.app.arn
#   desired_count   = 2
#   # where the tasks should run and the SG associated with the tasks
#   network_configuration {
#     security_groups = [aws_security_group.ecs_task.id]
#     subnets         = var.subnets[*].id
#   }
#   # Use EC2 capacity provider if EC2 is chosen, otherwise use Fargate
#   capacity_provider_strategy {
#     capacity_provider = aws_ecs_capacity_provider.main[0].name
#     base              = 1
#     weight            = 100
#   }

#   # distributes tasks over different AZs
#   ordered_placement_strategy {
#     type  = "spread"
#     field = "attribute:ecs.availability-zone"
#   }

#   lifecycle {
#     ignore_changes = [desired_count]
#   }
#   # make sure the load balancer is created first then routes traffic to port 80
#   depends_on = [aws_lb_target_group.app]

#   load_balancer {
#     target_group_arn = aws_lb_target_group.app.arn
#     container_name   = "app"
#     container_port   = 80
#   }
# }


# Creates the ECS service which orchestrates the desired number of tasks is running at all times
# this is looking to have 2 tasks running at all times
resource "aws_ecs_service" "app_fargate" {
  name            = "app"
  cluster         = var.ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  # where the tasks should run and the SG associated with the tasks
  network_configuration {
    security_groups = [var.security_group_ecs_task.id]
    subnets         = var.subnets[*].id
  }

  launch_type = "FARGATE"

  lifecycle {
    ignore_changes = [desired_count]
  }
  # make sure the load balancer is created first then routes traffic to port 80
  depends_on = [var.alb_target_group]

  load_balancer {
    target_group_arn = var.alb_target_group.arn
    container_name   = "app"
    container_port   = 80
  }
}