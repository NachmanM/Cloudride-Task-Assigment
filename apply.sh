#!/bin/bash
set -e

OIDC_ARN="arn:aws:iam::753392824297:oidc-provider/token.actions.githubusercontent.com"

tf_dir="-chdir=terraform"

cat > terraform/backend.tf << 'EOF'
terraform {
  backend "s3" {}
}
EOF

terraform $tf_dir init -reconfigure -backend-config=backend-configs/prod-backend.tfvars

terraform $tf_dir workspace select dev || terraform $tf_dir workspace new dev

terraform $tf_dir state list | grep -q 'module.aws_oidc.aws_iam_openid_connect_provider.github' || \
  terraform $tf_dir import module.aws_oidc.aws_iam_openid_connect_provider.github "$OIDC_ARN"

terraform $tf_dir state list | grep -q 'module.s3_state.aws_s3_bucket.state_bucket' || \
  terraform $tf_dir import module.s3_state.aws_s3_bucket.state_bucket "state-prod-default-project-name"

terraform $tf_dir apply -auto-approve

terraform $tf_dir workspace select prod || terraform $tf_dir workspace new prod

terraform $tf_dir state list | grep -q 'module.aws_oidc.aws_iam_openid_connect_provider.github' || \
  terraform $tf_dir import module.aws_oidc.aws_iam_openid_connect_provider.github "$OIDC_ARN"

terraform $tf_dir state list | grep -q 'module.s3_state.aws_s3_bucket.state_bucket' || \
  terraform $tf_dir import module.s3_state.aws_s3_bucket.state_bucket "state-prod-default-project-name"

terraform $tf_dir apply -auto-approve

echo "Script executed successfully!"