variable "aws_region" {
  description = "Region for everything except the ACM cert (which is forced to us-east-1)."
  type        = string
  default     = "eu-west-2"
}

variable "project" {
  description = "Name prefix for all resources."
  type        = string
  default     = "cloud-resume-challenge"
}

variable "use_custom_domain" {
  description = "true = serve on a custom domain (ACM + Route 53). false = deploy on the default *.cloudfront.net URL, no domain required."
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Full site domain, e.g. joshuabarradas.com. Only used when use_custom_domain = true."
  type        = string
  default     = ""
}

variable "hosted_zone_name" {
  description = "An existing Route 53 public hosted zone, e.g. joshuabarradas.com. Only used when use_custom_domain = true."
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub repo allowed to assume the deploy role, in owner/name form, e.g. joshuabarradas/cloud-resume-challenge"
  type        = string
}
