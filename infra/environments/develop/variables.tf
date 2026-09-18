variable "project_name" {
  type    = string
  default = "attendance-saas"
}

variable "environment" {
  type    = string
  default = "develop"
}

variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "availability_zones" {
  type    = list(string)
  default = ["ap-northeast-1a", "ap-northeast-1c"]
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.10.101.0/24", "10.10.102.0/24"]
}

variable "cluster_version" {
  type    = string
  default = "1.30"
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_desired_size" {
  type    = number
  default = 1
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 2
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "github_repository" {
  description = "owner/repo形式のGitHubリポジトリ名（OIDC trust policy用）"
  type        = string
  default     = "seyanakatamusic/testAITeamWorks2"
}

variable "tf_state_bucket" {
  description = "Terraformリモートステート用S3バケット名（bootstrap手順で事前作成する）"
  type        = string
}

variable "tf_lock_table" {
  description = "Terraformロック用DynamoDBテーブル名（S3 native lockingのため現状未使用。将来的な明示テーブル運用に備えた変数）"
  type        = string
  default     = ""
}
