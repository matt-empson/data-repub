// - Security Groups
// - Application Load Balancer
// - Autoscaling

// Security Groups
resource "aws_security_group" "app_alb_allow" {
  name        = "app_alb_allow"
  description = "Allowed APP ALB traffic"
  vpc_id      = var.vpc_id

  tags = {
    Name = "App ALB Permit"
  }
}

resource "aws_security_group_rule" "app_alb_allow_http_in" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web_alb_allow.id

  security_group_id = aws_security_group.app_alb_allow.id
}

resource "aws_security_group_rule" "app_alb_allow_https_in" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web_alb_allow.id

  security_group_id = aws_security_group.app_alb_allow.id
}

resource "aws_security_group_rule" "app_alb_allow_out" {
  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = -1
  cidr_blocks = [var.vpc_cidr]

  security_group_id = aws_security_group.app_alb_allow.id
}

resource "aws_security_group" "app_servers_allow" {
  name        = "app_servers_allow"
  description = "Allowed APP Server traffic"
  vpc_id      = var.vpc_id

  tags = {
    Name = "App Server Permit"
  }
}

resource "aws_security_group_rule" "app_server_allow_http_in" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app_alb_allow.id

  security_group_id = aws_security_group.app_servers_allow.id
}

resource "aws_security_group_rule" "app_server_allow_out" {
  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = -1
  cidr_blocks = [var.vpc_cidr]

  security_group_id = aws_security_group.app_servers_allow.id
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
  security_groups    = [aws_security_group.app_alb_allow.id]
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

// Autoscaling
resource "aws_launch_template" "app_tier" {
  name = "app_tier_launch_template"

  image_id               = data.aws_ami.app_tier.id
  instance_type          = "t3.small"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.app_servers_allow.id]

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = 8
      volume_type           = "gp2"
      delete_on_termination = true
    }
  }

  credit_specification {
    cpu_credits = "standard"
  }

  tags = {
    Name = "app_tier_launch_template"
  }
}

resource "aws_autoscaling_group" "app_tier" {
  name = "app_tier"

  availability_zones = data.aws_availability_zones.azs.names
  desired_capacity   = length(data.aws_availability_zones.azs.names)
  health_check_type  = "ELB"
  max_size           = 6
  min_size           = 1
  target_group_arns  = [aws_lb_target_group.app_tier.id]

  vpc_zone_identifier = data.aws_subnet_ids.app_tier.ids

  launch_template {
    id      = aws_launch_template.app_tier.id
    version = "$Latest"
  }

  tags = [
    {
      key                 = "Name"
      value               = "App Tier Autoscaling"
      propagate_at_launch = true
    },
  ]
}

resource "aws_autoscaling_policy" "app_tier_scale_up" {
  name                   = "app_tier_scale_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "SimpleScaling"
  cooldown               = 30
  autoscaling_group_name = aws_autoscaling_group.app_tier.name
}

resource "aws_autoscaling_policy" "app_tier_scale_down" {
  name                   = "app_tier_scale_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "SimpleScaling"
  cooldown               = 30
  autoscaling_group_name = aws_autoscaling_group.app_tier.name
}

resource "aws_cloudwatch_metric_alarm" "app_tier_cpu_high" {
  alarm_name          = "app_tier_cpu_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 35

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_tier.name
  }

  alarm_description = "Scale up if CPU utilization is above 35 for 300 seconds"
  alarm_actions     = [aws_autoscaling_policy.app_tier_scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "app_tier_cpu_low" {
  alarm_name          = "app_tier_cpu_low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 30

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_tier.name
  }

  alarm_description = "Scale down if the CPU utilization is below 30 for 300 seconds"
  alarm_actions     = [aws_autoscaling_policy.app_tier_scale_down.arn]
}