variable "access_key" {}
variable "secret_key" {}
variable "region" {
  default = "us-west-2"
}
variable "ami" {
  default = "ami-4836a428"
}

variable "instance_type" {
  default = "t2.micro"
}