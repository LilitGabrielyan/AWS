provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
  skip_credentials_validation = true
}

module "my-s3" {
  source = "./S3"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "${module.my-s3.s3_bucket_domain_name}"
    origin_id   = "myS3Origin"
  }
  enabled             = true
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "myS3Origin"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "https-only"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

// create lambda for deleting cloud fron cache after changes in s3
data "aws_iam_policy_document" "lambda_access" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
//  statement {
//    actions = [
//      "cloudfront:CreateInvalidation"
//    ]
//    effect = "Allow"
//    principals {
//      type        = "Service"
//      identifiers = ["lambda.amazonaws.com"]
//    }
//  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"
  assume_role_policy = "${data.aws_iam_policy_document.lambda_access.json}"
}

resource "aws_lambda_function" "cacheInvalidationStarted" {
  filename         = "functions/InvalidateCache.zip"
  function_name    = "Invalidation_started_trigger"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "cacheInvalidationStarted.invalidationStarted"
  runtime          = "nodejs4.3"
  environment {
    variables = {
      apiVersion = "${var.envVersion}}",
      region = "${var.region}"
    }
  }

}

resource "aws_lambda_function" "cacheInvalidationFinished" {
  filename         = "functions/InvalidateCache.zip"
  function_name    = "Invalidation_finished_trigger"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "cacheInvalidationFinished.invalidationFinished"
  runtime          = "nodejs4.3"
  environment {
    variables = {
      apiVersion = "${var.envVersion}}",
      region = "${var.region}"
    }
  }

}

resource "aws_lambda_function" "my_lambda" {
  filename         = "functions/InvalidateCache.zip"
  function_name    = "lambda_function_name"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "InvalidateCache.test"
  runtime          = "nodejs4.3"
  environment {
    variables = {
      distributionId = "${aws_cloudfront_distribution.s3_distribution.id}",
      apiVersion = "${var.envVersion}}",
      region = "${var.region}"
    }
  }

}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.my_lambda.arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${module.my-s3.s3_arn}"
}

resource "aws_lambda_alias" "my_alias" {
  name             = "myalias"
  description      = "a sample description"
  function_name    = "${aws_lambda_function.my_lambda.function_name}"
  function_version = "$LATEST"
}



//add events
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = "${module.my-s3.s3_id}"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.my_lambda.arn}"
    events              = ["s3:ObjectCreated:*"]
  }
}