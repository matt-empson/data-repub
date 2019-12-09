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

data "aws_subnet_ids" "public" {
  vpc_id = var.vpc_id

  tags = {
    Name = "PUBLIC*"
  }
}