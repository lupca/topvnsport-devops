terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  common_tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }

  # Actual AWS values (discovered via AWS CLI)
  ec2_subnet_id        = "subnet-02d90789c6c5af683"
  ec2_security_group   = "sg-0051b179f57a7ad15"
  rds_subnet_group     = "topvnsport-db-subnet"
  rds_security_group   = "sg-05043d7ea0114b259"
}

module "vpc" {
  source = "../../modules/vpc"

  name                = "${var.project}-${var.environment}"
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  availability_zones  = var.availability_zones
  tags                = local.common_tags
}

module "ec2" {
  source = "../../modules/ec2"

  name              = var.project
  ami_id            = var.ec2_ami_id
  key_name          = var.ec2_key_name
  subnet_id         = local.ec2_subnet_id
  security_group_id = local.ec2_security_group
  tags              = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  cluster_identifier      = "${var.project}-db"
  engine_version          = var.rds_engine_version
  master_password         = var.rds_master_password
  db_subnet_group_name    = local.rds_subnet_group
  security_group_id       = local.rds_security_group
  serverless_min_capacity = 0.5
  serverless_max_capacity = 8
  storage_encrypted       = true
  skip_final_snapshot     = false
  tags                    = local.common_tags
}

module "s3" {
  source = "../../modules/s3"

  bucket_name = "${var.project}-assets"
  tags        = local.common_tags
}
