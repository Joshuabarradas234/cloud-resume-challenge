variable "aws_region" {
  description = "Region for the state bucket and lock table (match the main stack)."
  type        = string
  default     = "eu-west-2"
}

variable "project" {
  type    = string
  default = "cloud-resume-challenge"
}

variable "state_bucket_name" {
  description = "Globally-unique name for the Terraform state bucket."
  type        = string
}

variable "lock_table_name" {
  description = "Name for the DynamoDB state-lock table."
  type        = string
  default     = "cloud-resume-challenge-tf-lock"
}
