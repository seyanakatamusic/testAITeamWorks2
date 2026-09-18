output "vpc_id" {
  value = module.network.vpc_id
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "db_instance_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "db_master_user_secret_arn" {
  description = "RDSマスターパスワードを保持するSecrets ManagerシークレットのARN（値そのものは出力しない）"
  value       = module.rds.master_user_secret_arn
}

output "github_deploy_role_arn" {
  description = "GitHub ActionsがOIDCでAssumeするデプロイ用IAMロールARN（Actions Variables `AWS_DEPLOY_ROLE_ARN` に設定する）"
  value       = module.oidc.deploy_role_arn
}
