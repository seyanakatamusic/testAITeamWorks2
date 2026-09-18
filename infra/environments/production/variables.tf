variable "project_name" {
  type    = string
  default = "attendance-saas"
}

variable "environment" {
  type    = string
  default = "production"
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
  default = "10.20.0.0/16"
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.101.0/24", "10.20.102.0/24"]
}

variable "cluster_version" {
  type    = string
  default = "1.30"
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.large"]
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 4
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.small"
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
  description = "Terraformロック用DynamoDBテーブル名"
  type        = string
  default     = ""
}
