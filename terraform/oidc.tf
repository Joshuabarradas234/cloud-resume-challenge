# GitHub Actions authenticates to AWS via OIDC — no stored access keys.
#
# If your account already has the GitHub OIDC provider, delete this resource and
# the tls data source, then reference the existing provider's ARN in the trust
# policy below (an account can only have one provider per URL).

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

# Trust policy: only this repo's main branch may assume the role.
data "aws_iam_policy_document" "gha_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.project}-gha-deploy"
  assume_role_policy = data.aws_iam_policy_document.gha_assume.json
}

# The runtime deploy steps: sync the site bucket and invalidate the CDN. Tightly
# scoped to exactly those resources.
data "aws_iam_policy_document" "gha_deploy_ops" {
  statement {
    sid       = "SiteSync"
    actions   = ["s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
    resources = [aws_s3_bucket.site.arn, "${aws_s3_bucket.site.arn}/*"]
  }

  statement {
    sid       = "Invalidate"
    actions   = ["cloudfront:CreateInvalidation", "cloudfront:GetInvalidation"]
    resources = [aws_cloudfront_distribution.site.arn]
  }
}

resource "aws_iam_role_policy" "gha_deploy_ops" {
  name   = "${var.project}-gha-deploy-ops"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.gha_deploy_ops.json
}

# The pipeline also runs `terraform apply`, which needs to manage every service
# in this stack. This is scoped to the services actually used — broader than the
# deploy-ops policy above, but far from AdministratorAccess. Tighten resource
# ARNs further if you want; start here rather than with admin.
data "aws_iam_policy_document" "gha_terraform" {
  statement {
    sid = "ManageStackServices"
    actions = [
      "s3:*",
      "cloudfront:*",
      "acm:*",
      "route53:*",
      "dynamodb:*",
      "lambda:*",
      "apigateway:*",
      "logs:*",
      "iam:GetRole",
      "iam:PassRole",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:TagRole",
      "iam:ListRolePolicies",
      "iam:GetRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:ListInstanceProfilesForRole",
      "sts:GetCallerIdentity",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "gha_terraform" {
  name   = "${var.project}-gha-terraform"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.gha_terraform.json
}
