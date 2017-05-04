variable "access_key" {}
variable "secret_key" {}
variable "region" {
  default = "us-west-2"
}
variable "private_range" {
  default = "10.0.2.0/24"
}

variable "public_range" {
  default = "10.0.0.0/24"
}

variable "az" {
  default = "us-west-2a"
}
variable "ami" {
  default = "ami-4836a428"
}

variable "instance_type" {
  default = "t2.micro"
}