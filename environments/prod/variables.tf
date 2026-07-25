variable "project" {
  description = "Project name"
  type        = string
  default     = "topvnsport"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "AWS region (the existing production infrastructure lives in us-east-1)"
  type        = string
  default     = "us-east-1"
}

# --- VPC ---
# Fill in after `aws ec2 describe-vpcs` / `aws ec2 describe-subnets` — see docs/migration-runbook.md
variable "vpc_cidr" {
  description = "CIDR block of the existing VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks of the existing public subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "AZs matching public_subnet_cidrs, in the same order"
  type        = list(string)
}

# --- EC2 ---
# Fill in after `aws ec2 describe-instances --instance-ids i-0ede7353edeef0c63`
variable "ec2_ami_id" {
  description = "AMI ID of the existing topvnsport instance"
  type        = string
}

variable "ec2_key_name" {
  description = "EC2 key pair name used by the existing instance"
  type        = string
}

# --- RDS ---
# Cluster: topvnsport-db (Aurora PostgreSQL Serverless v2)
variable "rds_engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "17.4"
}

variable "rds_master_password" {
  description = "Master password for the RDS cluster. Pass via TF_VAR_rds_master_password, never commit it"
  type        = string
  sensitive   = true
}
