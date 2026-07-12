output "site_url" {
  description = "The live site (custom domain if set, else the CloudFront URL)."
  value       = local.site_origin
}

output "cloudfront_url" {
  description = "Always the default CloudFront URL — useful before a custom domain is attached."
  value       = "https://${aws_cloudfront_distribution.site.domain_name}"
}

output "api_endpoint" {
  description = "Base URL of the counter API. The frontend calls <this>/count."
  value       = aws_apigatewayv2_api.counter.api_endpoint
}

output "cloudfront_distribution_id" {
  description = "Used by the pipeline to invalidate the cache."
  value       = aws_cloudfront_distribution.site.id
}

output "s3_bucket" {
  description = "Site origin bucket — the pipeline syncs the frontend here."
  value       = aws_s3_bucket.site.bucket
}

output "github_actions_role_arn" {
  description = "Set this as the AWS_DEPLOY_ROLE_ARN repository secret."
  value       = aws_iam_role.github_actions.arn
}
