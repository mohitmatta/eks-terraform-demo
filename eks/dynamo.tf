# DynamoDB Table for Stock Data
resource "aws_dynamodb_table" "stock-table" {
  name         = "stocks"                   # Table name
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

# Seed the table with an example item to establish the schema structure
resource "aws_dynamodb_table_item" "stock_item" {
  table_name = aws_dynamodb_table.stock-table.name
  hash_key   = aws_dynamodb_table.stock-table.hash_key

  item = <<ITEM
{
  "symbol": {"S": "TSLA"},
  "stockname": {"S": "Tesla Inc. Common Stock"},
  "lastsale": {"S": "$235.45"},
  "country": {"S": "United States"},
  "ipoyear": {"N": "2010"}
}
ITEM
}
