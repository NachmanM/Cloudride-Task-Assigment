#!/bin/bash
set -e

tf_dir="-chdir=terraform"

# ──────────────────────────────────────────────────────────────
# Step 1: Destroy dev infrastructure
# The shared S3 state bucket is excluded here so that the prod
# workspace state (still in S3) remains readable in step 2.
# The OIDC provider is always preserved across both workspaces.
# ──────────────────────────────────────────────────────────────
cat > terraform/backend.tf << 'EOF'
terraform {
  backend "s3" {}
}
EOF

terraform $tf_dir init -reconfigure -backend-config=backend-configs/prod-backend.tfvars

terraform $tf_dir workspace select dev

dev_targets=$(terraform $tf_dir state list | \
  grep -Ev '(module\.aws_oidc\.aws_iam_openid_connect_provider\.github|module\.s3_state\.)')

if [ -n "$dev_targets" ]; then
  terraform $tf_dir destroy $(echo "$dev_targets" | sed 's/^/-target=/') -auto-approve
fi

# ──────────────────────────────────────────────────────────────
# Step 2: Migrate prod state to local backend
# This frees the S3 bucket from active backend use so it can be
# deleted in the next step (force_destroy = true handles any
# residual state objects left in the bucket).
# ──────────────────────────────────────────────────────────────
terraform $tf_dir workspace select prod

cat > terraform/backend.tf << 'EOF'
terraform {
  backend "local" {}
}
EOF

terraform $tf_dir init -migrate-state

# ──────────────────────────────────────────────────────────────
# Step 3: Destroy prod infrastructure (including S3 state bucket)
# ──────────────────────────────────────────────────────────────
prod_targets=$(terraform $tf_dir state list | \
  grep -v 'module\.aws_oidc\.aws_iam_openid_connect_provider\.github')

if [ -n "$prod_targets" ]; then
  terraform $tf_dir destroy $(echo "$prod_targets" | sed 's/^/-target=/') -auto-approve
fi

echo "Script executed successfully!"