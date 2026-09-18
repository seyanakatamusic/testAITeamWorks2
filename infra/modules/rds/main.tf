# RDSマスターパスワードはTerraformに渡さず、Amazon RDSのmanage_master_user_password機能で
# AWS Secrets Managerに自動生成・保管させる（平文の資格情報をstate/コードに残さないため）。

resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_security_group" "rds" {
  name        = "${var.identifier}-rds-sg"
  description = "Allow Postgres access from EKS nodes only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Postgres from EKS node security group"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.allowed_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_db_instance" "this" {
  identifier     = var.identifier
  engine         = "postgres"
  engine_version = var.engine_version

  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"

  db_name  = var.database_name
  username = var.master_username

  # 長期固定パスワードを使わず、RDSにSecrets Managerでのシークレット管理を任せる
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az                  = var.multi_az
  publicly_accessible       = false
  storage_encrypted         = true
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.identifier}-final"
  backup_retention_period   = var.backup_retention_period

  tags = var.tags
}
