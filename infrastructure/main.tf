terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "k8s-microservices-tfstate-1761406163"  # ⚠️ REPLACE with your actual bucket name
    key            = "k8s-microservices/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "k8s-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "production"
      Project     = "k8s-microservices-platform"
      ManagedBy   = "terraform"
    }
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  cluster_name = var.cluster_name
  environment  = "production"
}
