# --- ECR ---
# elastic container registry, allows you to store your image which then ecs will run the container
resource "aws_ecr_repository" "app" {
  name                 = "demo-app"
  # The tag mutability setting for the repository. Must be one of: MUTABLE or IMMUTABLE. Defaults to MUTABLE.
  image_tag_mutability = "MUTABLE"
  # If true, will delete the repository even if it contains images. Defaults to false.
  force_delete         = true

# Indicates whether images are scanned after being pushed to the repository (true) or not scanned (false) for security concerns
  image_scanning_configuration {
    scan_on_push = true
  }
}