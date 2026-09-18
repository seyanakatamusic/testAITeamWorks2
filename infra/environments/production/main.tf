locals {
  cluster_name = "${var.project_name}-${var.environment}"
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

module "network" {
  source = "../../modules/network"

  project_name         = var.project_name
  environment          = var.environment
  cluster_name         = local.cluster_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  single_nat_gateway   = false # production環境はAZごとにNAT Gatewayを分散
  tags                 = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name        = local.cluster_name
  cluster_version     = var.cluster_version
  vpc_id              = module.network.vpc_id
  subnet_ids          = module.network.private_subnet_ids
  node_instance_types = var.node_instance_types
  node_capacity_type  = "ON_DEMAND"
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  node_desired_size   = var.node_desired_size
  tags                = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  identifier                = "${local.cluster_name}-db"
  vpc_id                    = module.network.vpc_id
  subnet_ids                = module.network.private_subnet_ids
  allowed_security_group_id = module.eks.node_security_group_id
  instance_class            = var.db_instance_class
  multi_az                  = true # productionは可用性優先
  deletion_protection       = true
  skip_final_snapshot       = false
  tags                      = local.common_tags
}

module "oidc" {
  source = "../../modules/oidc"

  project_name      = var.project_name
  github_repository = var.github_repository
  github_branch     = "main"
  role_name         = "${local.cluster_name}-github-deploy"
  tf_state_bucket   = var.tf_state_bucket
  tf_lock_table     = var.tf_lock_table
  tags              = local.common_tags
}
