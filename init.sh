#!/bin/bash
set -e

cat > terraform/backend.tf << 'EOF'
terraform {
  backend "local" {}
}
EOF

tf_dir="-chdir=terraform"

terraform $tf_dir init -migrate-state 

terraform $tf_dir state list | grep -q 'module.aws_oidc.aws_iam_openid_connect_provider.github' || \
  terraform $tf_dir import module.aws_oidc.aws_iam_openid_connect_provider.github \
    arn:aws:iam::753392824297:oidc-provider/token.actions.githubusercontent.com

terraform $tf_dir apply -auto-approve

cat > terraform/backend.tf << 'EOF'
terraform {
  backend "s3" {}
}
EOF

terraform $tf_dir init -migrate-state -backend-config=backend-configs/prod-backend.tfvars

terraform $tf_dir workspace select prod || terraform $tf_dir workspace new prod

terraform $tf_dir apply -auto-approve

echo "Script executed successfully!"