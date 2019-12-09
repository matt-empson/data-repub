resource "aws_instance" "bastion" {
  count = 1

  ami                    = data.aws_ami.centos.id
  key_name               = var.key_name
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.bastion_allow_in.id]
  subnet_id              = aws_subnet.public.*.id[count.index]

  associate_public_ip_address = true

  root_block_device {
    volume_size           = "8"
    volume_type           = "gp2"
    delete_on_termination = true
  }

  tags = {
    Name = "Bastion Host"
  }
}
