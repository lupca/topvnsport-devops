output "cluster_id" {
  description = "RDS cluster ID"
  value       = aws_rds_cluster.main.id
}

output "cluster_endpoint" {
  description = "Writer endpoint"
  value       = aws_rds_cluster.main.endpoint
}

output "cluster_reader_endpoint" {
  description = "Reader endpoint"
  value       = aws_rds_cluster.main.reader_endpoint
}

output "security_group_id" {
  description = "Security group ID (created or existing)"
  value       = local.security_group_id
}

output "db_subnet_group_name" {
  description = "DB subnet group name (created or existing)"
  value       = local.db_subnet_group_name
}
