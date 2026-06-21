#!/bin/bash

cat > terraform/backend.tf << 'EOF'
terraform {
  backend "local" {}
}
EOF

tf_dir="-chdir=terraform"

terraform $tf_dir init -migrate-state

targets=$(terraform $tf_dir state list | grep -v "module.aws_oidc.aws_iam_openid_connect_provider.github")

terraform $tf_dir destroy $(echo "$targets" | sed 's/^/-target=/') -auto-approve