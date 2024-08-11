provider "aws" {
  region = "eu-west-1"
}

terraform {
  backend "s3" {
    bucket         = "terraform-state.sneeu.com"
    key            = "projects/noughts-and-crosses/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state.sneeu.com"
}

resource "aws_s3_bucket_ownership_controls" "terraform_state_ownership_controls" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "terraform_state_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.terraform_state_ownership_controls]

  bucket = aws_s3_bucket.terraform_state.id
  acl    = "private"
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "Noughts-and-Crosses-Lambda-Function-Role"
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_policy" "iam_policy_for_lambda" {
  name        = "aws-iam-policy-for-terraform-aws-lambda-role"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role"
  policy      = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:*:*:*",
        "Effect": "Allow"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
}

#data "archive_file" "zip_the_python_code" {
#  type        = "zip"
#  source_dir  = "${path.module}/python/"
#  output_path = "${path.module}/python/hello-python.zip"
#}

resource "aws_lambda_function" "terraform_lambda_func" {
  architectures = ["arm64"]
  filename      = "${path.module}/../target/lambda/noughts-and-crosses/bootstrap.zip"
  function_name = "noughts_and_crosses"
  role          = aws_iam_role.lambda_role.arn
  handler       = "bootstrap"
  runtime       = "provided.al2023"
  depends_on    = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}
