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

//data "aws_iam_policy_document" "bucket_policy" {
//  statement {
//    effect = "Allow"
//    actions = [
//      "s3:*"]
//    principals = {
//      type = "*"
//      identifiers = [
//        "*"]
//    }
//  }
//
//}
//
//resource "aws_s3_bucket_policy" "my_policy" {
//  bucket = "${aws_s3_bucket.myS3.id}"
//  policy = "${data.aws_iam_policy_document.bucket_policy.json}"
//}

data "aws_iam_policy_document" "s3_access" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.myS3.bucket}",
      "arn:aws:s3:::${aws_s3_bucket.myS3.bucket}/*",
    ]
  }
}

resource "aws_iam_user" "test_user" {
  name = "${var.user}"
}

resource "aws_iam_access_key" "test_user" {
  user = "${aws_iam_user.test_user.name}"
}

resource "aws_iam_user_policy" "test_user_policy" {
  name = "test"
  user = "${aws_iam_user.test_user.name}"
  policy = "${data.aws_iam_policy_document.s3_access.json}"
}