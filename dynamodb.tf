resource "aws_dynamodb_table" "vault" {
  name           = "vault-backend"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "Path"
  range_key      = "Key"

  attribute {
    name = "Path"
    type = "S"
  }

  attribute {
    name = "Key"
    type = "S"
  }
}
