provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
  skip_credentials_validation = true
}

resource "aws_s3_bucket" "myS3" {
  bucket = "s3-website-test.lilit.com"
  acl = "public-read"
  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

output "s3_bucket_domain_name" {
  value = "${aws_s3_bucket.myS3.bucket_domain_name}"
}

output "s3_id" {
  value = "${aws_s3_bucket.myS3.id}"
}

output "s3_arn" {
  value = "${aws_s3_bucket.myS3.arn}"
}