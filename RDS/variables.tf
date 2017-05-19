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
variable "private_ranges" {type = "list"
  default = ["10.0.2.0/24"]
}

variable "public_ranges" {type = "list"
  default = ["10.0.0.0/24"]
}

variable "azs" {type = "list" default = ["us-west-2a"]}

variable "dbName" {
  default = "myDb"
}

variable "dbUserName" {
  default = "dbuser"
}

variable "dbPassword" {
  default = "dbpassword"
}

variable "dbStorage" {
  default = 10
}

variable "dbEngine" {
  default = "mariadb"
}

variable "dbInstance" {
  default = "db.t2.micro"
}