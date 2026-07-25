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

  name      = var.project
  ami_id    = var.ec2_ami_id
  key_name  = var.ec2_key_name
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnet_ids[0]
  tags      = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  cluster_identifier         = "database-${var.project}"
  engine_version             = var.rds_engine_version
  master_password            = var.rds_master_password
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.public_subnet_ids
  allowed_security_group_ids = [module.ec2.security_group_id]
  tags                       = local.common_tags
}

module "s3" {
  source = "../../modules/s3"

  bucket_name = "${var.project}-assets"
  tags        = local.common_tags
}
