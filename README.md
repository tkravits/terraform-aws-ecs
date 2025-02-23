# terraform-aws-ecs

# After `terraform apply` we need to connect our ECR to our local docker login

### Get AWS repo url from Terraform outputs
export REPO=$(terraform output --raw demo_app_repo_url)
### Login to AWS ECR
aws ecr get-login-password | docker login --username AWS --password-stdin $REPO

### Pull docker image & push to our ECR
docker pull --platform linux/amd64 strm/helloworld-http:latest
docker tag strm/helloworld-http:latest $REPO:latest
docker push $REPO:latest