# DynamoDB Table for Stock Data
resource "aws_dynamodb_table" "stock-table" {
  name         = "Stocks"                   # Table name
  billing_mode = "PAY_PER_REQUEST"              # Billing mode: scales costs based on usage
  hash_key     = "symbol"                # Partition key for uniquely identifying items

  # Table schema definition
  attribute {
    name = "symbol"                      # Name of the partition key attribute
    type = "S"                                  # Data type of the attribute (string)
  }

  # Time-To-Live (TTL) configuration
  ttl {
    attribute_name = "TimeToExist"              # Attribute for expiration timestamps
    enabled        = false                      # TTL is disabled
  }

  # Resource lifecycle settings
  lifecycle {
    ignore_changes = [ttl]                      # Ignore changes to TTL configuration
  }
}
