variable "db_instance_type" {
  default = "db.t2.small"
}

variable "key_name" {
  default = "matt.empson"
}

variable "vpc_id" {
  default = "vpc-021ea5d5d4b8e2e16"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}