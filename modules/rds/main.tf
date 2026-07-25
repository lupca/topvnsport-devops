# RDS Module - supports both "create new" and "use existing" patterns

# DB Subnet Group: create new OR use existing
resource "aws_db_subnet_group" "this" {
  count      = var.existing_db_subnet_group_name == "" ? 1 : 0
  name       = "${var.cluster_identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, { Name = "${var.cluster_identifier}-subnet-group" })
}

data "aws_db_subnet_group" "existing" {
  count = var.existing_db_subnet_group_name != "" ? 1 : 0
  name  = var.existing_db_subnet_group_name
}

locals {
  db_subnet_group_name = var.existing_db_subnet_group_name != "" ? data.aws_db_subnet_group.existing[0].name : aws_db_subnet_group.this[0].name
}

# Security Group: create new OR use existing
resource "aws_security_group" "rds" {
  count       = var.existing_security_group_id == "" ? 1 : 0
  name        = "${var.cluster_identifier}-sg"
  description = "Security group for ${var.cluster_identifier}"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks     = var.allowed_cidr_blocks
    security_groups = var.allowed_security_group_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.cluster_identifier}-sg" })
}

data "aws_security_group" "existing" {
  count = var.existing_security_group_id != "" ? 1 : 0
  id    = var.existing_security_group_id
}

locals {
  security_group_id = var.existing_security_group_id != "" ? data.aws_security_group.existing[0].id : aws_security_group.rds[0].id
}

# RDS Aurora Cluster
resource "aws_rds_cluster" "main" {
  cluster_identifier      = var.cluster_identifier
  engine                  = "aurora-postgresql"
  engine_mode             = "provisioned"
  engine_version          = var.engine_version
  master_username         = var.master_username
  master_password         = var.master_password
  db_subnet_group_name    = local.db_subnet_group_name
  vpc_security_group_ids  = [local.security_group_id]
  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = var.skip_final_snapshot
  storage_encrypted       = var.storage_encrypted

  serverlessv2_scaling_configuration {
    min_capacity = var.serverless_min_capacity
    max_capacity = var.serverless_max_capacity
  }

  tags = merge(var.tags, { Name = var.cluster_identifier })

  lifecycle {
    ignore_changes = [master_password, availability_zones]
  }
}

resource "aws_rds_cluster_instance" "main" {
  identifier         = "${var.cluster_identifier}-instance-1"
  cluster_identifier = aws_rds_cluster.main.id
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version
  instance_class     = "db.serverless"

  tags = merge(var.tags, { Name = "${var.cluster_identifier}-instance-1" })
}
