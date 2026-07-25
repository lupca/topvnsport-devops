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

variable "db_subnet_group_name" {
  description = "Name of existing DB subnet group"
  type        = string
}

variable "security_group_id" {
  description = "Existing security group ID for the RDS cluster"
  type        = string
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

variable "backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when destroying"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
