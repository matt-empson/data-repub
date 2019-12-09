resource "aws_security_group" "web_alb_allow_in" {
  name        = "web_alb_allow_in"
  description = "Allowed WEB ALB traffic INBOUND"
  vpc_id      = var.vpc_id

  tags = {
    Name = "Web ALB Permit INBOUND"
  }
}

resource "aws_security_group_rule" "web_alb_allow_http_in" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.web_alb_allow_in.id
}

resource "aws_security_group_rule" "web_alb_allow_https_in" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.web_alb_allow_in.id
}

resource "aws_security_group" "web_servers_allow_in" {
  name        = "web_servers_allow_in"
  description = "Allowed WEB Server traffic INBOUND"
  vpc_id      = var.vpc_id

  tags = {
    Name = "Web Server Permit INBOUND"
  }
}

resource "aws_security_group_rule" "web_server_allow_http_in" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web_alb_allow_in.id

  security_group_id = aws_security_group.web_servers_allow_in.id
}