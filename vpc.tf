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

///*
//  Public Subnet
//*/
resource "aws_subnet" "us-west-2a-public" {
  vpc_id = "${aws_vpc.my_vpc.id}"

  cidr_block = "10.0.0.0/24"
  availability_zone = "us-west-2a"

  tags {
    Name = "Public Subnet"
  }
  depends_on = ["aws_vpc.my_vpc"]
}

resource "aws_subnet" "us-west-2b-public" {
  vpc_id = "${aws_vpc.my_vpc.id}"

  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2b"

  tags {
    Name = "Public Subnet"
  }
  depends_on = ["aws_vpc.my_vpc"]
}

/*
  Create nat gateway in us-west-2a-public public subnet
*/
resource "aws_eip" "nat" {
  vpc = true
}


resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id = "${aws_subnet.us-west-2a-public.id}"
  depends_on = [
    "aws_internet_gateway.my_igw"]
}

/*
  Private Subnet
*/
resource "aws_subnet" "us-west-2a-private" {
  vpc_id = "${aws_vpc.my_vpc.id}"

  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-2a"

  tags {
    Name = "Private Subnet"
  }
  depends_on = ["aws_vpc.my_vpc"]
}

resource "aws_subnet" "us-west-2b-private" {
  vpc_id = "${aws_vpc.my_vpc.id}"

  cidr_block = "10.0.3.0/24"
  availability_zone = "us-west-2b"

  tags {
    Name = "Private Subnet"
  }
  depends_on = ["aws_vpc.my_vpc"]
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

resource "aws_route_table_association" "eu-west-1a-public" {
  subnet_id = "${aws_subnet.us-west-2a-private.id}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "eu-west-1a-public" {
  subnet_id = "${aws_subnet.us-west-2b-private.id}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "eu-west-1a-public" {
  subnet_id = "${aws_subnet.us-west-2b-public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "eu-west-1a-public" {
  subnet_id = "${aws_subnet.us-west-2a-public.id}"
  route_table_id = "${aws_route_table.public.id}"
}
