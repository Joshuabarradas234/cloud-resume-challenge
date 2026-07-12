output "state_bucket" {
  value = aws_s3_bucket.state.id
}

output "lock_table" {
  value = aws_dynamodb_table.lock.name
}

# Copy this block straight into ../terraform/backend.tf (backend blocks can't
# read variables or outputs, so the values must be pasted in literally).
output "backend_block" {
  description = "Paste into terraform/backend.tf"
  value       = <<-EOT
    bucket         = "${aws_s3_bucket.state.id}"
    key            = "cloud-resume-challenge/terraform.tfstate"
    region         = "${var.aws_region}"
    dynamodb_table = "${aws_dynamodb_table.lock.name}"
    encrypt        = true
  EOT
}
