resource "aws_db_subnet_group" "main" {
  name       = "${var.cluster_identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-subnet-group"
  })
}

resource "aws_security_group" "rds" {
  name        = "${var.cluster_identifier}-sg"
  description = "Security group for the ${var.cluster_identifier} Aurora cluster"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from application security groups"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-sg"
  })
}

resource "aws_rds_cluster" "main" {
  cluster_identifier        = var.cluster_identifier
  engine                    = "aurora-postgresql"
  engine_version            = var.engine_version
  database_name             = var.database_name
  master_username           = var.master_username
  master_password           = var.master_password
  db_subnet_group_name      = aws_db_subnet_group.main.name
  vpc_security_group_ids    = [aws_security_group.rds.id]
  backup_retention_period   = var.backup_retention_period
  final_snapshot_identifier = "${var.cluster_identifier}-final"
  skip_final_snapshot       = false

  tags = merge(var.tags, {
    Name = var.cluster_identifier
  })

  # Password rotation is handled outside Terraform (e.g. AWS Secrets Manager);
  # importing an existing cluster should not force a password reset.
  lifecycle {
    ignore_changes = [master_password]
  }
}

resource "aws_rds_cluster_instance" "main" {
  identifier         = "${var.cluster_identifier}-instance-1"
  cluster_identifier = aws_rds_cluster.main.id
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version
  instance_class     = var.instance_class

  tags = merge(var.tags, {
    Name = "${var.cluster_identifier}-instance-1"
  })
}
