terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web" {
  ami           = "ami-069aabeee6f53e7bf"
  instance_type = "t2.micro"

  tags = {
    Name = "Terraform-server"
  }
}

# terraform init
# terraform fmt
# terraform validate
# terraform plan
# terraform apply