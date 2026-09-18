variable "cluster_name" {
  description = "EKSクラスタ名"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetesバージョン"
  type        = string
  default     = "1.30"
}

variable "vpc_id" {
  description = "EKSを配置するVPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "ノードグループ/コントロールプレーンENIを配置するサブネットID一覧（通常はprivate subnet）"
  type        = list(string)
}

variable "node_instance_types" {
  description = "マネージドノードグループのインスタンスタイプ"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "ON_DEMAND または SPOT"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 2
}

variable "node_desired_size" {
  type    = number
  default = 1
}

variable "tags" {
  description = "共通タグ"
  type        = map(string)
  default     = {}
}
