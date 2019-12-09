// - Security Groups
// - Application Load Balancer
// - Autoscaling

// Security Groups
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

// Application Load Balancer
resource "aws_lb_target_group" "web_tier" {
  name     = "web-tier"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  tags = {
    Name = "Web Tier"
  }
}

resource "aws_lb" "web_tier" {
  name               = "web-tier"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_alb_allow_in.id]
  subnets            = data.aws_subnet_ids.public.ids

  tags = {
    Name = "web-tier-alb"
  }
}

resource "aws_lb_listener" "web_tier" {
  load_balancer_arn = aws_lb.web_tier.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tier.arn
  }
}