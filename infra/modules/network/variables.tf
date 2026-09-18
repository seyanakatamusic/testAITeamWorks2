variable "project_name" {
  description = "プロジェクト名（リソース命名prefix）"
  type        = string
}

variable "environment" {
  description = "環境名（develop/production等）"
  type        = string
}

variable "cluster_name" {
  description = "このVPCを利用するEKSクラスタ名（サブネットのkubernetes.ioタグ用）"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "使用するAZ一覧"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "プライベートサブネットCIDR一覧"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "パブリックサブネットCIDR一覧"
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "true の場合NAT Gatewayを1つに集約してコストを削減する（develop向け）"
  type        = bool
  default     = true
}

variable "tags" {
  description = "共通タグ"
  type        = map(string)
  default     = {}
}
