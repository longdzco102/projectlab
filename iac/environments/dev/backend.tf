# Backend is intentionally partial. Real values are injected at init time so that
# bucket / table names are not committed to the repository:
#
#   terraform init -backend-config=backend.hcl
#
# Copy backend.hcl.example -> backend.hcl and fill in the real values.
# backend.hcl is git-ignored.
terraform {
  backend "s3" {}
}
