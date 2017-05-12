provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
  skip_credentials_validation = true
}

module "my-vpc" {
  source = "./vpc"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

resource "aws_security_group" "my_sg" {

  vpc_id = "${module.my-vpc.vpcID}"

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
  subnet_id = "${module.my-vpc.publicSubnetId}"
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"

}

resource "aws_instance" "private_instance" {
  security_groups = [
    "${aws_security_group.my_sg.id}"
  ]
  subnet_id = "${module.my-vpc.privateSubnetId}"
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
    "${module.my-vpc.publicSubnetId}"]
}

/*
Create instanc in each subnet
*/

resource "aws_eip" "public_ip" {
  instance = "${aws_instance.public_instance.id}"
  vpc = true
}


