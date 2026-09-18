variable "create_oidc_provider" {
  description = "trueの場合IAM OIDCプロバイダを新規作成する。AWSアカウントに既存のGitHub OIDCプロバイダがある場合はfalseにしてexisting_oidc_provider_arnを指定する"
  type        = bool
  default     = true
}

variable "existing_oidc_provider_arn" {
  description = "create_oidc_provider=falseの場合に使う既存OIDCプロバイダARN"
  type        = string
  default     = ""
}

variable "github_repository" {
  description = "owner/repo形式のGitHubリポジトリ名（trust policyのsub条件に使用）"
  type        = string
}

variable "github_branch" {
  description = "AssumeRoleWithWebIdentityを許可するブランチ名"
  type        = string
  default     = "develop"
}

variable "role_name" {
  description = "GitHub Actionsがassumeするデプロイ用IAMロール名"
  type        = string
}

variable "project_name" {
  description = "IAMロール/インスタンスプロファイルのPassRole範囲を絞るための命名prefix"
  type        = string
}

variable "tf_state_bucket" {
  description = "Terraformリモートステート用S3バケット名"
  type        = string
}

variable "tf_lock_table" {
  description = "Terraformロック用DynamoDBテーブル名"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
