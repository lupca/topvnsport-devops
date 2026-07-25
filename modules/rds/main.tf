# Use existing subnet group and security group
data "aws_db_subnet_group" "main" {
  name = var.db_subnet_group_name
}

data "aws_security_group" "rds" {
  id = var.security_group_id
}

resource "aws_rds_cluster" "main" {
  cluster_identifier      = var.cluster_identifier
  engine                  = "aurora-postgresql"
  engine_mode             = "provisioned"
  engine_version          = var.engine_version
  master_username         = var.master_username
  master_password         = var.master_password
  db_subnet_group_name    = data.aws_db_subnet_group.main.name
  vpc_security_group_ids  = [data.aws_security_group.rds.id]
  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = var.skip_final_snapshot
  storage_encrypted       = var.storage_encrypted

  serverlessv2_scaling_configuration {
    min_capacity = var.serverless_min_capacity
    max_capacity = var.serverless_max_capacity
  }

  tags = merge(var.tags, {
    Name = var.cluster_identifier
  })

  lifecycle {
    ignore_changes = [
      master_password,
      availability_zones,
      db_subnet_group_name,
      vpc_security_group_ids,
    ]
  }
}

resource "aws_rds_cluster_instance" "main" {
  identifier         = "${var.cluster_identifier}-instance-1"
  cluster_identifier = aws_rds_cluster.main.id
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version
  instance_class     = "db.serverless"

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-instance-1"
  })
}
