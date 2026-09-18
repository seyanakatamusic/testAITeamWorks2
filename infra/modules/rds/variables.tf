variable "identifier" {
  description = "RDSインスタンス識別子"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  description = "DBサブネットグループに使うプライベートサブネットID一覧"
  type        = list(string)
}

variable "allowed_security_group_id" {
  description = "Postgresへの接続を許可するセキュリティグループ（通常はEKSノードSG）"
  type        = string
}

variable "engine_version" {
  type    = string
  default = "16.4"
}

variable "instance_class" {
  description = "develop環境はコスト最適化のため小さめのインスタンスクラスを使う"
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "max_allocated_storage" {
  type    = number
  default = 100
}

variable "database_name" {
  type    = string
  default = "attendance"
}

variable "master_username" {
  type    = string
  default = "app_admin"
}

variable "multi_az" {
  description = "develop環境はfalse（コスト最適化）。production環境はtrue推奨"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "backup_retention_period" {
  type    = number
  default = 1
}

variable "tags" {
  type    = map(string)
  default = {}
}
