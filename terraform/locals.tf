locals {
  # The origin browsers actually hit. With a custom domain it's that domain;
  # otherwise it's the CloudFront-assigned hostname (known after apply). This
  # feeds both the API's CORS allow-list and the Lambda's ALLOWED_ORIGIN, so
  # they always match the real site origin without hardcoding anything.
  site_domain = var.use_custom_domain ? var.domain_name : aws_cloudfront_distribution.site.domain_name
  site_origin = "https://${local.site_domain}"
}
