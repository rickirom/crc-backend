resource "aws_dynamodb_table" "vctable" {
  name           = "VisitorCount"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "visitor-count-table"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_dynamodb_table_item" "vc_seed" {
  # This resource seeds the table for the first time. I treat this as infra cause it's the codified
  # equivalent to going to the console and creating the item. After creation the app owns the item
  # that's why we add the ignore_changes lifecycle rule

  table_name = aws_dynamodb_table.vctable.name
  hash_key   = aws_dynamodb_table.vctable.hash_key

  item = jsonencode({
    id    = { S = "visitor-count" }
    views = { N = "0" }
  })

  lifecycle {
    ignore_changes = [item]
  }
}