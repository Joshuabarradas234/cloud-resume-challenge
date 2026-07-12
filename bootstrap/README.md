# Bootstrap: remote state backend

Creates the S3 bucket + DynamoDB lock table that the main stack uses for remote
state. Run this **once**, before the main stack.

This exists because Terraform's S3 backend needs its bucket and table to already
exist before `init` — the classic chicken-and-egg. Rather than leave manual
`aws` CLI commands in the README, that setup is itself Terraform: versioned,
encrypted, repeatable.

> Note: this does not make the whole project a single `apply`. It's two —
> `apply` here once, then `apply` in `../terraform`. What it replaces is the
> manual bucket/table creation, not the main deploy.

## Run

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars   # set a globally-unique bucket name
terraform init      # local state — no backend yet, that's the point
terraform apply
terraform output backend_block                 # paste result into ../terraform/backend.tf
```

Then move to `../terraform` and follow the main README.

## State

This config uses **local state** on purpose (it's building the remote backend,
so it can't use it). The state file only tracks a bucket and a table; if it's
ever lost, re-import with `terraform import` — nothing here is precious. It's
gitignored by the repo-root `.gitignore`.
