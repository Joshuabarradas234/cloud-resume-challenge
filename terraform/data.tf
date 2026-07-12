data "aws_caller_identity" "current" {}

data "aws_route53_zone" "primary" {
  count        = var.use_custom_domain ? 1 : 0
  name         = var.hosted_zone_name
  private_zone = false
}
