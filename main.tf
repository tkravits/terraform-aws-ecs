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
