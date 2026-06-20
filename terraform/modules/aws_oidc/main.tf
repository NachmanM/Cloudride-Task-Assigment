import {
  to = aws_iam_openid_connect_provider.github
  id = "arn:aws:iam::753392824297:oidc-provider/token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role" "github_actions_ecr" {
  name = "github-actions-ecr-runner-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TrustGitHubOIDC"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:NachmanM/*:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ecr_push_policy" {
  name        = "github-actions-ecr-push-policy"
  description = "Granular permissions for pushing images to ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAuthTokenExchange"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRUploadPermissions"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ecr" {
  role       = aws_iam_role.github_actions_ecr.name
  policy_arn = aws_iam_policy.ecr_push_policy.arn
}

resource "aws_iam_policy" "github_tf_backend_policy" {
  name        = "github-actions-tf-backend-policy"
  description = "Allows GitHub Actions to read and write Terraform state to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListBucketForTerraform"
        Effect = "Allow"
        Action = [
            "s3:*"
        ]
        Resource = "arn:aws:s3:::state-prod-default-project-name"
      },
      {
        Sid    = "ReadWriteStateAndLocks"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::state-prod-default-project-name/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_backend_policy" {
  role       = aws_iam_role.github_actions_ecr.name
  policy_arn = aws_iam_policy.github_tf_backend_policy.arn
}

resource "aws_iam_policy" "github_ecs_deploy_policy" {
  name        = "github-actions-ecs-deploy-policy"
  description = "Allows GitHub Actions to register task definitions and update ECS services"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECSUpdateService"
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ]
        Resource = "arn:aws:ecs:us-east-1:753392824297:service/prod-default-project-name/*"
      },
      {
        Sid    = "ECSTaskDefinitionManagement"
        Effect = "Allow"
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition"
        ]
        # RegisterTaskDefinition requires "*" because task definitions are globally scoped family names
        Resource = "*" 
      },
      {
        Sid    = "PassExecutionRole"
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        # The runner needs permission to pass your ECS Execution/Task roles to the ECS service
        Resource = [
          "arn:aws:iam::753392824297:role/cloudride-challenge-app-ecsTaskExecutionRole",
          "arn:aws:iam::753392824297:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS"
        ]
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ecs_deploy" {
  role       = aws_iam_role.github_actions_ecr.name
  policy_arn = aws_iam_policy.github_ecs_deploy_policy.arn
}

resource "aws_iam_policy" "github_tf_read_policy" {
  name        = "github-actions-tf-read-policy"
  description = "Read-only permissions for Terraform state refresh across all managed resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2ReadForTerraformRefresh"
        Effect = "Allow"
        Action = [
          "ec2:DescribeAddresses",
          "ec2:DescribeAddressesAttribute",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeNatGateways",
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSecurityGroupRules",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcAttribute",
          "ec2:DescribeVpcs"
        ]
        Resource = "*"
      },
      {
        Sid    = "IAMReadForTerraformRefresh"
        Effect = "Allow"
        Action = [
          "iam:GetOpenIDConnectProvider",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:GetRole",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:ListRolePolicies"
        ]
        Resource = "*"
      },
      {
        Sid    = "ELBReadForTerraformRefresh"
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:DescribeListenerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTags",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetGroups"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECSAndECRReadForTerraformRefresh"
        Effect = "Allow"
        Action = [
          "ecs:DescribeClusters",
          "ecs:ListTagsForResource",
          "ecr:DescribeRepositories",
          "ecr:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchLogsReadForTerraformRefresh"
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:ListTagsForResource",
          "logs:ListTagsLogGroup"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_tf_read" {
  role       = aws_iam_role.github_actions_ecr.name
  policy_arn = aws_iam_policy.github_tf_read_policy.arn
}