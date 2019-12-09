variable "bastion_allow_in" {
  default = ["61.14.103.50/32"]
}

variable "key_name" {
  default = "matt.empson"
}

variable "instance_type" {
  default = "t2.micro"
}
variable "tag_name" {
  default = "Data Republic"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}