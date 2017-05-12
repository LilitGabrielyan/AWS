variable "access_key" {}
variable "secret_key" {}
variable "region" {
  default = "us-west-2"
}
variable "private_ranges" {type = "list"
  default = ["10.0.2.0/24"]
}

variable "public_ranges" {type = "list"
  default = ["10.0.0.0/24"]
}

variable "azs" {type = "list" default = ["us-west-2a"]}
