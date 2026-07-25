variable "cluster_identifier" {
  description = "Identifier of the Aurora cluster (must match the existing cluster being imported)"
  type        = string
}

variable "engine_version" {
  description = "Aurora PostgreSQL engine version (must match the existing cluster)"
  type        = string
}

variable "master_username" {
  description = "Master username for the cluster"
  type        = string
  default     = "postgres"
}

variable "master_password" {
  description = "Master password for the cluster. Do not hardcode - pass via TF_VAR_rds_master_password or a secret manager"
  type        = string
  sensitive   = true
}

variable "database_name" {
  description = "Name of the default database created with the cluster"
  type        = string
  default     = "postgres"
}

variable "serverless_min_capacity" {
  description = "Minimum ACU capacity for Serverless v2"
  type        = number
  default     = 0.5
}

variable "serverless_max_capacity" {
  description = "Maximum ACU capacity for Serverless v2"
  type        = number
  default     = 8
}

variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID to launch the RDS security group in"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the DB subnet group (must span at least 2 AZs)"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect to the database on port 5432"
  type        = list(string)
  default     = []
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
