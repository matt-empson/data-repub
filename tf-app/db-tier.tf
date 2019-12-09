resource "aws_security_group" "db_servers_allow_in" {
  name        = "db_servers_allow_in"
  description = "Allowed DB Server traffic INBOUND"
  vpc_id      = var.vpc_id

  tags = {
    Name = "DB Server Permit INBOUND"
  }
}

resource "aws_security_group_rule" "db_allow_in" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app_servers_allow_in.id

  security_group_id = aws_security_group.db_servers_allow_in.id
}

resource "aws_db_subnet_group" "db" {
  name       = "data_republic_subnet_group"
  subnet_ids = data.aws_subnet_ids.db_tier.ids

  tags = {
    Name = "Data Republic DB Subnet Group"
  }
}

resource "aws_rds_cluster" "db" {
  cluster_identifier     = "data-republic-db"
  db_subnet_group_name   = aws_db_subnet_group.db.name
  engine                 = "aurora-mysql"
  engine_mode            = "provisioned"
  master_password        = "barbarbarbar"
  master_username        = "foo"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.db_servers_allow_in.id]

  tags = {
    Name = "Data Republic DB"
  }
}

resource "aws_rds_cluster_instance" "db_instances" {
  count                = 2
  identifier           = "data-republic-db-${count.index}"
  engine               = "aurora-mysql"
  db_subnet_group_name = aws_db_subnet_group.db.name
  cluster_identifier   = aws_rds_cluster.db.id
  instance_class       = var.db_instance_type
}