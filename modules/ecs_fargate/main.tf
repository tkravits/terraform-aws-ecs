# --- ECS Task Role ---
# creates the policy document for ECS tasks so they can assume the IAM role.
# This will be assigned to the ecs_task_role to make it more readable that
# the IAM is assuming this role
data "aws_iam_policy_document" "ecs_exec_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
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
  assume_role_policy = data.aws_iam_policy_document.ecs_exec_role.json
}
# AWS has a specific role found in the policy ARN, create this policy attachment and 
# attach it to the ecs_exec role
resource "aws_iam_role_policy_attachment" "ecs_exec_role_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
# --- ECS Task Definition ---
# Creates the task definition that tells ECS how to run the image
resource "aws_ecs_task_definition" "app" {
  family             = "demo-app-fargate"
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
    image        = "${var.ecr_url}:latest",
    # if the container fails, restart
    essential    = true,
    # host port is always mapped with awsvpc
    portMappings = [{ containerPort = 80 }],
    # add environment variables to the container
    environment = [
      { name = "EXAMPLE", value = "example" }
    ]

    # configures cloudwatch logs
    logConfiguration = {
      logDriver = "awslogs",
      options = {
        "awslogs-region"        = "us-east-1",
        "awslogs-group"         = var.cloudwatch_logs_name,
        "awslogs-stream-prefix" = "app"
      }
    },
  }])
}

# --- ECS Service ---
# Creates the ECS service which orchestrates the desired number of tasks is running at all times
# this is looking to have 2 tasks running at all times
resource "aws_ecs_service" "app_fargate" {
  name            = "app"
  cluster         = var.ecs_cluster.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  # where the tasks should run and the SG associated with the tasks
  network_configuration {
    security_groups = [var.security_group_ecs_task.id]
    subnets         = var.subnets[*].id
    assign_public_ip = "true"
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