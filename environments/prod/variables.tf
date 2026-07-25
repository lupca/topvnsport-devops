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
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# --- VPC ---
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
}

# --- EC2 ---
variable "ec2_ami_id" {
  description = "AMI ID"
  type        = string
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "ec2_key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "ec2_subnet_id" {
  description = "Existing subnet ID for EC2. If empty, uses VPC module output."
  type        = string
  default     = ""
}

variable "ec2_existing_sg_id" {
  description = "Existing security group ID for EC2. If empty, creates new."
  type        = string
  default     = ""
}

# --- RDS ---
variable "rds_engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "17.4"
}

variable "rds_master_password" {
  description = "Master password (pass via TF_VAR_rds_master_password)"
  type        = string
  sensitive   = true
}

variable "rds_min_capacity" {
  description = "Serverless min ACU"
  type        = number
  default     = 0.5
}

variable "rds_max_capacity" {
  description = "Serverless max ACU"
  type        = number
  default     = 8
}

variable "rds_existing_subnet_group" {
  description = "Existing DB subnet group name. If empty, creates new."
  type        = string
  default     = ""
}

variable "rds_existing_sg_id" {
  description = "Existing security group ID for RDS. If empty, creates new."
  type        = string
  default     = ""
}

# --- S3 ---
variable "s3_bucket_name" {
  description = "S3 bucket name"
  type        = string
}
