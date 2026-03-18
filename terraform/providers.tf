terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

terraform {
  backend "s3" {
  }
}

provider "aws" {
  # Uses AWS CLI configuration (aws configure)
}

provider "aws" {
  alias  = "ap_southeast_2"
  region = "ap-southeast-2"
}

data "aws_caller_identity" "current" {}