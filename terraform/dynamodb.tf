resource "aws_dynamodb_table" "visits" {
  name         = "${var.project}-visits"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}
