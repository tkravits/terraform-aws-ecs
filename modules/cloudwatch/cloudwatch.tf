# --- Cloud Watch Logs ---

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/demo"
  retention_in_days = 14
}

output "ecs_cloudwatch_logs" {
  value = aws_cloudwatch_log_group.ecs
}