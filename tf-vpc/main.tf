provider "aws" {
  region = "ap-southeast-2"
}

// Remote State
terraform {
  backend "s3" {
    bucket = "matte-tfstate"
    key    = "vpc/terraform.tfstate"
    region = "ap-southeast-2"
  }

  required_version = ">= 0.12.17"
}
