# main.tf
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {
    bucket = "uniplus-rep-g5"
    key    = "aws-uniplus/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" { region = "us-east-1" }