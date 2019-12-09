// Create VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.tag_name}-VPC"
  }
}

// Create IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.tag_name}-IGW"
  }
}

// Create NAT Gateways
resource "aws_eip" "ngw_eip" {
  count = length(data.aws_availability_zones.azs.names)

  vpc = true

  tags = {
    Name = "${var.tag_name}-NGW-EIP-${data.aws_availability_zones.azs.names[count.index]}"
  }
}

resource "aws_nat_gateway" "multi_az_ngw" {
  count = length(data.aws_availability_zones.azs.names)

  allocation_id = aws_eip.ngw_eip.*.id[count.index]

  depends_on = [aws_eip.ngw_eip]
  subnet_id  = aws_subnet.public.*.id[count.index]

  tags = {
    Name = "${var.tag_name}-NGW-${data.aws_availability_zones.azs.names[count.index]}"
  }
}

// Create Subnets
resource "aws_subnet" "public" {
  count = length(data.aws_availability_zones.azs.names)

  availability_zone = data.aws_availability_zones.azs.names[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 6, count.index)
  vpc_id            = aws_vpc.vpc.id

  tags = {
    Name = "PUBLIC-${data.aws_availability_zones.azs.names[count.index]}"
  }
}

resource "aws_subnet" "app_tier" {
  count = length(data.aws_availability_zones.azs.names)

  availability_zone = data.aws_availability_zones.azs.names[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 6, count.index + length(data.aws_availability_zones.azs.names))
  vpc_id            = aws_vpc.vpc.id

  tags = {
    Name = "APP-Tier-${data.aws_availability_zones.azs.names[count.index]}"
  }
}

resource "aws_subnet" "db_tier" {
  count = length(data.aws_availability_zones.azs.names)

  availability_zone = data.aws_availability_zones.azs.names[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 6, count.index + length(data.aws_availability_zones.azs.names) * 2)
  vpc_id            = aws_vpc.vpc.id

  tags = {
    Name = "DB-Tier-${data.aws_availability_zones.azs.names[count.index]}"
  }
}

resource "aws_subnet" "web_tier" {
  count = length(data.aws_availability_zones.azs.names)

  availability_zone = data.aws_availability_zones.azs.names[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 6, count.index + length(data.aws_availability_zones.azs.names) * 3)
  vpc_id            = aws_vpc.vpc.id

  tags = {
    Name = "WEB-Tier-${data.aws_availability_zones.azs.names[count.index]}"
  }
}

resource "aws_subnet" "mgmt_tier" {
  count = length(data.aws_availability_zones.azs.names)

  availability_zone = data.aws_availability_zones.azs.names[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 6, count.index + length(data.aws_availability_zones.azs.names) * 4)
  vpc_id            = aws_vpc.vpc.id

  tags = {
    Name = "MGMT-Tier-${data.aws_availability_zones.azs.names[count.index]}"
  }
}

// Create Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "PUBLIC"
  }
}

resource "aws_route_table" "app_tier" {
  count = length(data.aws_availability_zones.azs.names)

  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "APP-Tier-${data.aws_availability_zones.azs.names[count.index]}"
  }
}

resource "aws_route_table" "db_tier" {
  count = length(data.aws_availability_zones.azs.names)

  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "DB-Tier-${data.aws_availability_zones.azs.names[count.index]}"
  }
}

resource "aws_route_table" "web_tier" {
  count = length(data.aws_availability_zones.azs.names)

  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "WEB-Tier-${data.aws_availability_zones.azs.names[count.index]}"
  }
}

resource "aws_route_table" "mgmt_tier" {
  count = length(data.aws_availability_zones.azs.names)

  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "MGMT-Tier-${data.aws_availability_zones.azs.names[count.index]}"
  }
}

// Associate Route Tables
resource "aws_route_table_association" "public" {
  count = length(data.aws_availability_zones.azs.names)

  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public.*.id[count.index]
}

resource "aws_route_table_association" "app_tier" {
  count = length(data.aws_availability_zones.azs.names)

  route_table_id = aws_route_table.app_tier.*.id[count.index]
  subnet_id      = aws_subnet.app_tier.*.id[count.index]
}

resource "aws_route_table_association" "db_tier" {
  count = length(data.aws_availability_zones.azs.names)

  route_table_id = aws_route_table.db_tier.*.id[count.index]
  subnet_id      = aws_subnet.db_tier.*.id[count.index]
}

resource "aws_route_table_association" "web_tier" {
  count = length(data.aws_availability_zones.azs.names)

  route_table_id = aws_route_table.web_tier.*.id[count.index]
  subnet_id      = aws_subnet.web_tier.*.id[count.index]
}

resource "aws_route_table_association" "mgmt_tier" {
  count = length(data.aws_availability_zones.azs.names)

  route_table_id = aws_route_table.mgmt_tier.*.id[count.index]
  subnet_id      = aws_subnet.mgmt_tier.*.id[count.index]
}

// Create Routes
resource "aws_route" "public_igw" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  route_table_id         = aws_route_table.public.id
}

resource "aws_route" "web_tier_default" {
  count = length(data.aws_availability_zones.azs.names)

  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.multi_az_ngw.*.id[count.index]
  route_table_id         = aws_route_table.web_tier.*.id[count.index]
}

resource "aws_route" "mgmt_tier_default" {
  count = length(data.aws_availability_zones.azs.names)

  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.multi_az_ngw.*.id[count.index]
  route_table_id         = aws_route_table.mgmt_tier.*.id[count.index]
}