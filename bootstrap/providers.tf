terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }

  # Local state, deliberately. This config *creates* the S3 remote-state backend
  # that the main stack uses, so it can't store its own state there. Its state
  # only tracks a bucket and a table — both trivially re-importable if lost.
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform"
      Component = "tf-state-bootstrap"
    }
  }
}
