provider "aws" {
  profile = "default"
  region = "sa-east-1"
}

resource "aws_s3_bucket" "prod_tf_course" {
  bucket = "tf-course-15111996"
  acl = "private"
}

resource "aws_default_vpc" "default" {}
