data "aws_availability_zones" "azs" {}

data "aws_ami" "app_tier" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["Data Republic - app tier*"]
  }
}

data "aws_ami" "web_tier" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["Data Republic - web tier*"]
  }
}

data "aws_subnet_ids" "app_tier" {
  vpc_id = var.vpc_id

  tags = {
    Name = "APP-Tier*"
  }
}

data "aws_subnet_ids" "db_tier" {
  vpc_id = var.vpc_id

  tags = {
    Name = "DB-Tier*"
  }
}

data "aws_subnet_ids" "web_tier" {
  vpc_id = var.vpc_id

  tags = {
    Name = "WEB-Tier*"
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = var.vpc_id

  tags = {
    Name = "PUBLIC*"
  }
}