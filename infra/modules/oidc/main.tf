# GitHub Actions OIDC フェデレーション用のIAM IDプロバイダとデプロイロール。
# 長期アクセスキーを一切使わず、GitHub Actions実行時に一時クレデンシャルを発行させる。

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]

  tags = var.tags
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.existing_oidc_provider_arn
}

data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # 対象リポジトリの developブランチへのpushからのみAssumeを許可する
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repository}:ref:refs/heads/${var.github_branch}"]
    }
  }
}

resource "aws_iam_role" "deploy" {
  name                 = var.role_name
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  max_session_duration = 3600

  tags = var.tags
}

# EKS/Terraformのdeployに必要な範囲に絞ったポリシー（最小権限）。
# S3/DynamoDBはリモートステート用バケット・テーブルのみに限定する。
data "aws_iam_policy_document" "deploy" {
  statement {
    sid    = "TerraformStateAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${var.tf_state_bucket}",
      "arn:aws:s3:::${var.tf_state_bucket}/*",
    ]
  }

  statement {
    sid    = "TerraformLockTable"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]
    resources = [
      "arn:aws:dynamodb:*:*:table/${var.tf_lock_table}",
    ]
  }

  # VPC/EKS/RDSをTerraformでapplyするために必要な範囲のプロビジョニング権限。
  # 対象リソースのARNは作成前には確定しないため、AdministratorAccessのような
  # 全許可ではなく、サービス単位でアクション名を明示列挙する形で最小化する。
  statement {
    sid    = "NetworkProvisioning"
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "ec2:CreateVpc",
      "ec2:DeleteVpc",
      "ec2:ModifyVpcAttribute",
      "ec2:CreateSubnet",
      "ec2:DeleteSubnet",
      "ec2:ModifySubnetAttribute",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:CreateRouteTable",
      "ec2:DeleteRouteTable",
      "ec2:CreateRoute",
      "ec2:DeleteRoute",
      "ec2:AssociateRouteTable",
      "ec2:DisassociateRouteTable",
      "ec2:CreateInternetGateway",
      "ec2:DeleteInternetGateway",
      "ec2:AttachInternetGateway",
      "ec2:DetachInternetGateway",
      "ec2:AllocateAddress",
      "ec2:ReleaseAddress",
      "ec2:CreateNatGateway",
      "ec2:DeleteNatGateway",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "EksProvisioning"
    effect = "Allow"
    actions = [
      "eks:*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "RdsProvisioning"
    effect = "Allow"
    actions = [
      "rds:Describe*",
      "rds:CreateDBInstance",
      "rds:DeleteDBInstance",
      "rds:ModifyDBInstance",
      "rds:CreateDBSubnetGroup",
      "rds:DeleteDBSubnetGroup",
      "rds:ModifyDBSubnetGroup",
      "rds:AddTagsToResource",
      "rds:RemoveTagsFromResource",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "SecretsManagerForRds"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = ["arn:aws:secretsmanager:*:*:secret:rds!*"]
  }

  statement {
    sid    = "AutoScalingForNodeGroups"
    effect = "Allow"
    actions = [
      "autoscaling:Describe*",
      "autoscaling:CreateAutoScalingGroup",
      "autoscaling:DeleteAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
      "autoscaling:CreateOrUpdateTags",
      "autoscaling:DeleteTags",
    ]
    resources = ["*"]
  }

  # EKS/ノードグループ/OIDC federation用のIAMロール作成に限定したIAM権限。
  # PassRoleはEKS/RDS関連の想定パスに絞る。
  statement {
    sid    = "IamForEksAndOidc"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:GetOpenIDConnectProvider",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:GetRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:PassRole",
    ]
    resources = [
      "arn:aws:iam::*:role/${var.project_name}-*",
      "arn:aws:iam::*:instance-profile/${var.project_name}-*",
      "arn:aws:iam::*:oidc-provider/*",
    ]
  }
}

resource "aws_iam_role_policy" "deploy" {
  name   = "${var.role_name}-policy"
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.deploy.json
}
