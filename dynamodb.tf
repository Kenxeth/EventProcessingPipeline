resource "aws_dynamodb_table" "userevents-dynamodb-table" {
  name           = "user-events-table"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "user_id"
  range_key      = "event_type"

  attribute {
    name = "user_id"
    type = "N"
  }

  attribute {
    name = "event_type"
    type = "S"
  }


  ttl {
    attribute_name = "TimeToExist"
    enabled        = true
  }

  global_secondary_index {
    name               = "EventTypeIndex"
    key_schema {
      attribute_name = "user_id"
      key_type       = "HASH"
    }
    write_capacity     = 10
    read_capacity      = 10
    projection_type    = "INCLUDE"
    non_key_attributes = ["UserId"]
  }

  tags = {
    Name        = "dynamodb-table-1"
    Environment = "production"
  }
}