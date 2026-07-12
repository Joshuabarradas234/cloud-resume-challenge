terraform {
  backend "s3" {
    bucket         = "cloud-resume-challenge-tfstate-664418992605"
    key            = "cloud-resume-challenge/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "cloud-resume-challenge-tf-lock"
    encrypt        = true
  }
}
