provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
  skip_credentials_validation = true
}

/*
  Create my vpc
*/
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
}

/*
  Internet gateway
*/
resource "aws_internet_gateway" "my_igw" {
  vpc_id = "${aws_vpc.my_vpc.id}"
  depends_on = ["aws_vpc.my_vpc"]
}

/*
  Create nat gateway in us-west-2a-public public subnet
*/
resource "aws_eip" "nat" {
  vpc = true
}

/*
 Create NAT Gateway in 1 subnet
*/
resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.nat.id}"
//  subnet_id = "${element(aws_subnet.public.*.id, ${length(var.private_ranges) - 1})}"
  subnet_id = "${aws_subnet.public.0.id}"
  depends_on = [
    "aws_internet_gateway.my_igw"]
}

/*
  Private Subnet
*/
resource "aws_subnet" "private" {
  vpc_id = "${aws_vpc.my_vpc.id}"
  cidr_block = "${element(var.private_ranges, count.index)}"
  availability_zone = "${element(var.azs, count.index)}"
  count = "${length(var.private_ranges)}"
  tags {
    Name = "subnet_private_${count.index}"
  }
}

/*
  Public subnet
*/
resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.my_vpc.id}"
  cidr_block = "${element(var.public_ranges, count.index)}"
  availability_zone = "${element( var.azs, count.index)}"
  count = "${length(var.public_ranges)}"
  tags {
    Name = "subnet_public_${count.index}"
  }
  map_public_ip_on_launch = true
}


resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.my_vpc.id}"

  route = {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.gw.id}"
  }
  tags {
    Name = "Private Subnet"
  }
  depends_on = ["aws_vpc.my_vpc"]
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.my_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.my_igw.id}"
  }

  tags {
    Name = "Public Subnet"
  }
  depends_on = ["aws_vpc.my_vpc"]
}

/*
 Associate all private subnets with nat gateway
*/
resource "aws_route_table_association" "private_subnet_tables" {
  count = "${length(var.private_ranges)}"
  subnet_id = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${aws_route_table.private.id}"
}

/*
 Associate all public subnets with internet gateway
*/
resource "aws_route_table_association" "public_subnet_tables" {
  count = "${length(var.private_ranges)}"
  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

output "vpcID" {
  value = "${aws_vpc.my_vpc.id}"
}

output "publicSubnetId" {
  value = "${aws_subnet.public.0.id}"
}

output "privateSubnetId" {
  value = "${aws_subnet.private.0.id}"
}