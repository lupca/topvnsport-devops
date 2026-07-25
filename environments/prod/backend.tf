# State backend must be created out-of-band before `terraform init`
# (see docs/migration-runbook.md, Phase 1: State Backend Setup).
terraform {
  backend "s3" {
    bucket         = "topvnsport-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
