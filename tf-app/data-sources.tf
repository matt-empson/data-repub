data "aws_subnet_ids" "db_tier" {
  vpc_id = var.vpc_id

  tags = {
    Name = "DB-Tier*"
  }
}