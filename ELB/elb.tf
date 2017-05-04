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
  depends_on = [
    "aws_vpc.my_vpc"]
}

resource "aws_eip" "nat" {
  vpc = true
}

/*
 Create NAT Gateway in 1 subnet
*/
resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id = "${aws_subnet.public.id}"
  depends_on = [
    "aws_internet_gateway.my_igw"]
}

/*
  Private Subnet
*/
resource "aws_subnet" "private" {
  vpc_id = "${aws_vpc.my_vpc.id}"
  cidr_block = "${var.private_range}"
  availability_zone = "${var.az}"
  tags {
    Name = "subnet_private"
  }
}

/*
  Public subnet
*/
resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.my_vpc.id}"
  cidr_block = "${var.public_range}"
  availability_zone = "${var.az}"
  tags {
    Name = "subnet_public"
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
  depends_on = [
    "aws_vpc.my_vpc"]
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
  depends_on = [
    "aws_vpc.my_vpc"]
}

/*
 Associate all private subnets with nat gateway
*/
resource "aws_route_table_association" "private_subnet_table" {
  subnet_id = "${aws_subnet.private.id}"
  route_table_id = "${aws_route_table.private.id}"
}

/*
 Associate all public subnets with internet gateway
*/
resource "aws_route_table_association" "public_subnet_table" {
  subnet_id = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_security_group" "my_sg" {

  vpc_id = "${aws_vpc.my_vpc.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}

resource "aws_instance" "public_instance" {
  security_groups = [
    "${aws_security_group.my_sg.id}"]
  subnet_id = "${aws_subnet.public.id}"
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"

}

resource "aws_instance" "private_instance" {
  security_groups = [
    "${aws_security_group.my_sg.id}"
  ]
  subnet_id = "${aws_subnet.private.id}"
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"

}

resource "aws_elb" "my_elb" {

  listener {
    instance_port = 8000
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  listener {
    instance_port = 8000
    instance_protocol = "http"
    lb_port = 443
    lb_protocol = "http"
  }

  security_groups = [
    "${aws_security_group.my_sg.id}"]
  instances = [
    "${aws_instance.private_instance.id}"]
  subnets = [
    "${aws_subnet.public.id}"]
}

/*
Create instanc in each subnet
*/

resource "aws_eip" "public_ip" {
  instance = "${aws_instance.public_instance.id}"
  vpc = true
}


