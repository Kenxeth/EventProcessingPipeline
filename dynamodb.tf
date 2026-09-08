resource "aws_dynamodb_table" "userid-eventid-table" {
  name           = "userid-eventid-table"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "user_id"
  range_key      = "event_id"

  attribute {
    name = "user_id"
    type = "N"
  }

  attribute {
    name = "event_id"
    type = "N"
  }


  ttl {
    attribute_name = "TimeToExist"
    enabled        = true
  }


  tags = {
    Name        = "dynamodb-table-1"
    Environment = "production"
  }
}