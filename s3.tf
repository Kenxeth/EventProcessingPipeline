resource "aws_s3_bucket" "store_userResponse_bucket" {
  bucket = "store-userresponse"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

