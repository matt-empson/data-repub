// - Security Groups
// - Application Load Balancer
// - Autoscaling

// Security Groups
resource "aws_security_group" "app_alb_allow_in" {
  name        = "app_alb_allow_in"
  description = "Allowed APP ALB traffic INBOUND"
  vpc_id      = var.vpc_id

  tags = {
    Name = "App ALB Permit INBOUND"
  }
}

resource "aws_security_group_rule" "app_alb_allow_http_in" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web_alb_allow_in.id

  security_group_id = aws_security_group.app_alb_allow_in.id
}

resource "aws_security_group_rule" "app_alb_allow_https_in" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web_alb_allow_in.id

  security_group_id = aws_security_group.app_alb_allow_in.id
}

resource "aws_security_group" "app_servers_allow_in" {
  name        = "app_servers_allow_in"
  description = "Allowed APP Server traffic INBOUND"
  vpc_id      = var.vpc_id

  tags = {
    Name = "App Server Permit INBOUND"
  }
}

resource "aws_security_group_rule" "app_server_allow_http_in" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app_alb_allow_in.id

  security_group_id = aws_security_group.app_servers_allow_in.id
}

// Application Load Balancer
resource "aws_lb_target_group" "app_tier" {
  name     = "app-tier"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  tags = {
    Name = "App Tier"
  }
}

resource "aws_lb" "app_tier" {
  name               = "app-tier"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app_alb_allow_in.id]
  subnets            = data.aws_subnet_ids.app_tier.ids

  tags = {
    Name = "app-tier-alb"
  }
}

resource "aws_lb_listener" "app_tier" {
  load_balancer_arn = aws_lb.app_tier.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tier.arn
  }
}