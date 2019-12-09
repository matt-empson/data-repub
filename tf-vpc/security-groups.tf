resource "aws_security_group" "bastion_allow_in" {
  name        = "bastion_allow_in"
  description = "Allowed Bastion traffic INBOUND"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "Bastion Permit INBOUND"
  }
}

resource "aws_security_group_rule" "bastion_ssh_in" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = var.bastion_allow_in

  security_group_id = aws_security_group.bastion_allow_in.id
}