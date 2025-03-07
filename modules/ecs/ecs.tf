# --- ECS Cluster ---
# simple ECS cluster
resource "aws_ecs_cluster" "main" {
  name = "demo-cluster"
}


# --- ECS Node SG ---
# creates a security group
# Security groups are required to control traffic going to and from resources
resource "aws_security_group" "ecs_node_sg" {
  name_prefix = "demo-ecs-node-sg-"
  vpc_id      = var.vpc_id
}

# Manages an outbound (egress) rule for a security group. Was defining inline for the ecs_node security group but
# Terraform best practice recommends separating them as 
# "they struggle with managing multiple CIDR blocks, and tags and descriptions due to the historical lack of unique IDs."
# By default AWS security groups allow all outbound traffic but explicitly defining the rule is better for the user
resource "aws_vpc_security_group_egress_rule" "ecs_node_sg" {
  security_group_id = aws_security_group.ecs_node_sg.id

    from_port   = 0
    to_port     = 65535
    ip_protocol    = "tcp"
    cidr_ipv4 = "0.0.0.0/0"
}

# --- ALB ---
# creates the application load balancer security group that accepts traffic from port 80 and 443
resource "aws_security_group" "http" {
  name_prefix = "http-sg-"
  description = "Allow all HTTP/HTTPS traffic from public"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = [80, 443]
    content {
      protocol    = "tcp"
      from_port   = ingress.value
      to_port     = ingress.value
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

resource "aws_vpc_security_group_egress_rule" "http" {
  security_group_id = aws_security_group.http.id
    # Use -1 to specify all protocols. 
    # Note that if ip_protocol is set to -1, it translates to all protocols, all port ranges, and from_port and to_port values should not be defined.
    ip_protocol    = "-1"
    cidr_ipv4 = "0.0.0.0/0"
}



resource "aws_security_group" "ecs_task" {
  name_prefix = "ecs-task-sg-"
  description = "Allow all traffic within the VPC"
  vpc_id      = var.vpc_id

}

resource "aws_vpc_security_group_ingress_rule" "ecs_task" {
  security_group_id = aws_security_group.ecs_task.id
    # Use -1 to specify all protocols. 
    # Note that if ip_protocol is set to -1, it translates to all protocols, all port ranges, and from_port and to_port values should not be defined.
    ip_protocol    = "-1"
    cidr_ipv4 = var.cidr_block
}

resource "aws_vpc_security_group_egress_rule" "ecs_task" {
  security_group_id = aws_security_group.ecs_task.id
    # Use -1 to specify all protocols. 
    # Note that if ip_protocol is set to -1, it translates to all protocols, all port ranges, and from_port and to_port values should not be defined.
    ip_protocol    = "-1"
    cidr_ipv4 = "0.0.0.0/0"
}
# creates the application load balancer which distributes traffic
resource "aws_lb" "main" {
  name               = "demo-alb"
  load_balancer_type = "application"
  subnets            = var.subnets[*].id
  security_groups    = [aws_security_group.http.id]
}
# ALB will route traffic based off of the target group rules
# This gets attached to the ecs tasks with the load balancer that is 
# associated with the ECS tasks
resource "aws_lb_target_group" "app" {
  name_prefix = "app-"
  vpc_id      = var.vpc_id
  protocol    = "HTTP"
  port        = 80
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/"
    port                = 80
    matcher             = 200
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}
# listener forwards traffic to the target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.id
  }
}