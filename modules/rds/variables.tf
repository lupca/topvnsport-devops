variable "cluster_identifier" {
  description = "RDS cluster identifier"
  type        = string
}

variable "engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "master_username" {
  description = "Master username"
  type        = string
  default     = "postgres"
}

variable "master_password" {
  description = "Master password"
  type        = string
  sensitive   = true
}

# For creating new resources
variable "vpc_id" {
  description = "VPC ID (required if creating new SG)"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Subnet IDs for DB subnet group (required if creating new)"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect"
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect"
  type        = list(string)
  default     = []
}

# For using existing resources
variable "existing_db_subnet_group_name" {
  description = "Existing DB subnet group name. If empty, creates new one."
  type        = string
  default     = ""  # Empty = create new
}

variable "existing_security_group_id" {
  description = "Existing security group ID. If empty, creates new one."
  type        = string
  default     = ""  # Empty = create new
}

# Scaling
variable "serverless_min_capacity" {
  description = "Min ACU for Serverless v2"
  type        = number
  default     = 0.5
}

variable "serverless_max_capacity" {
  description = "Max ACU for Serverless v2"
  type        = number
  default     = 8
}

# Other
variable "storage_encrypted" {
  type    = bool
  default = true
}

variable "backup_retention_period" {
  type    = number
  default = 7
}

variable "skip_final_snapshot" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
