# Cloud Resume Challenge

A personal résumé site that stays live at a real domain — static frontend on
private S3 behind CloudFront, with a serverless visitor counter, deployed
entirely by Terraform and GitHub Actions.

**Live:** https://joshuabarradas.com

> Fill in the live URL above as the first thing a reader sees, once it's up.

---

## What it is

The frontend is plain HTML/CSS/JS — no framework — served from a **private** S3
bucket that only CloudFront can read (Origin Access Control), over HTTPS with an
ACM certificate. On load, the page calls an API that atomically increments a
visitor count in DynamoDB and returns the new total, which is rendered as live
telemetry in the status bar.

Everything is Terraform with remote state. Every push to `main` runs the tests,
applies the infrastructure, syncs the site, and invalidates the CDN cache —
authenticating to AWS with **OIDC**, so there are no long-lived AWS keys stored
anywhere.

## Architecture

```
Browser ──▶ Route 53 (A/AAAA alias) ──▶ CloudFront (OAC) ──▶ private S3 (index.html, css, js)
                                              │ HTTPS via ACM cert (us-east-1)
page JS on load
   │  POST /count
   ▼
API Gateway (HTTP API) ──▶ Lambda (Python) ──▶ DynamoDB
                            atomic UpdateItem: ADD count 1
```

## How the counter works

The page sends one `POST /count` on load. The Lambda runs a single atomic
DynamoDB `UpdateItem` with `ADD count 1` and returns the new value — one
round-trip, no read-before-write. Because the increment happens server-side in
one operation, two simultaneous visitors can never both read N and both write
N+1, so no visit is ever lost under concurrency.

## Live metrics

All measured on the running system, not estimated.

| Metric | Value | Source |
|---|---|---|
| Lighthouse (Perf / A11y / Best Practices / SEO), desktop | **100 / 100 / 100 / 100** | `docs/evidence/lighthouse.png` |
| Lambda execution (warm) | **~33-44 ms** | CloudWatch `REPORT` lines |
| Lambda execution (higher/cold path) | ~248 ms | CloudWatch `REPORT` lines |
| Lambda memory used | **94 MB of 128 MB** | CloudWatch `REPORT` lines |
| API round-trip, warm | ~300 ms | `curl -w` timing |
| API round-trip, cold start | ~3.6 s | `curl -w` timing |
| Backend tests | **5 passing** (pytest + moto) | CI log |
| CI/CD pipeline | ~1 min, OIDC auth (no stored keys) | GitHub Actions run |
| Monthly cost | free tier / pennies | S3 + CloudFront + Lambda + DynamoDB on-demand |

Notes: the Lambda is sized at 128 MB and uses 94 MB - no over-provisioning. The
cold-start figure is the honest first-request cost of a scale-to-zero function;
warm requests are the steady state. All numbers were measured on this system.


## Security notes

- S3 bucket is private; public access fully blocked. CloudFront reads it via OAC only.
- HTTPS enforced (`redirect-to-https`), TLS 1.2+.
- GitHub Actions uses OIDC role assumption — **no stored AWS access keys**.
- The Lambda role is least-privilege: write its own logs and `UpdateItem` on the one table. Nothing else.

## First-time setup

**1. Bootstrap remote state (once).** Terraform's S3 backend needs a state
bucket and lock table to exist *before* `init`. That setup is itself Terraform,
in `bootstrap/` — a versioned, encrypted state bucket and a lock table:

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars   # set a globally-unique bucket name
terraform init && terraform apply
terraform output backend_block                 # paste into ../terraform/backend.tf
```

This is a one-time step. It doesn't collapse the project to a single `apply` —
you still apply the main stack next — it just replaces manual `aws` CLI setup
with repeatable IaC. See `bootstrap/README.md`.

**2. Prerequisites.** A registered domain with a **public Route 53 hosted zone
already created** for it. Set your values in `terraform/terraform.tfvars` (copy
from `terraform.tfvars.example`).

**3. First apply (by hand).**

```bash
cd terraform
terraform init
terraform validate
terraform plan
terraform apply
```

Then set the counter endpoint in `frontend/counter.js` to the `api_endpoint`
output (with `/count` appended), upload the frontend once, and confirm the site
resolves over HTTPS and the counter ticks:

```bash
terraform output          # note s3_bucket, api_endpoint, cloudfront_distribution_id
aws s3 sync ../frontend s3://<s3_bucket> --delete
aws cloudfront create-invalidation --distribution-id <id> --paths "/*"
```

**4. Wire up CI/CD.** In the GitHub repo, add one secret,
`AWS_DEPLOY_ROLE_ARN`, set to the `github_actions_role_arn` output. After that,
every push to `main` deploys automatically — the pipeline injects the API
endpoint into `counter.js` itself, so you don't hardcode it.

## Run it yourself / tests

```bash
pip install -r backend/requirements.txt
pytest backend/tests -v
```

## Repository layout

```
frontend/    index.html, styles.css, counter.js
backend/     lambda/handler.py + tests/ (pytest + moto)
bootstrap/   one-time: creates the S3 + DynamoDB remote-state backend
terraform/   all infrastructure (private S3, CloudFront, ACM, Route 53,
             DynamoDB, Lambda, API Gateway, GitHub OIDC role, remote state)
.github/     deploy.yml — test → apply → sync → invalidate, OIDC auth
docs/        evidence/ (metric screenshots)
```

## Notes / honest scope

This is a personal site with a visitor counter — a carefully engineered one, not
an "enterprise" system, and it isn't described as one. The value is that it's
real, serverless, fully IaC, tested, and permanently live at a custom domain.
The metrics above are all things measured on infrastructure I own, so they're
verifiable rather than asserted.
