# terraform-aws-ecs
This repo is designed to be a resource to use terraform to create an ECS service with a task. It's based off of this article (https://medium.com/@vladkens/aws-ecs-cluster-on-ec2-with-terraform-2023-fdb9f6b7db07) with some changes to create modules and some egress/ingress updates. However, this can either use EC2 as a ECS node or Fargate

Run `terraform apply` to build the ECS environment, it will ask you if you would like to build using EC2 or Fargate
Then we will need to connect our ECR to our local environment to push a docker image to the ECR for the task to run

### Get AWS repo url from Terraform outputs
`export REPO=$(terraform output --raw demo_app_repo_url)`
### Login to AWS ECR
`aws ecr get-login-password --profile <profile name> --region <region> | docker login --username AWS --password-stdin $REPO`
### Pull docker image & push to our ECR
`docker pull --platform linux/amd64 strm/helloworld-http:latest`
`docker tag strm/helloworld-http:latest $REPO:latest`
`docker push $REPO:latest`

After all the resources are created and the ECR has the docker image, run 
`curl $(terraform output --raw alb_url)`
which will perform a GET to the application load balancer and serve back the hostname