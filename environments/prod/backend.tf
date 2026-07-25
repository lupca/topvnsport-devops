# Uncomment and configure for remote state
# terraform {
#   backend "s3" {
#     bucket         = "topvnsport-terraform-state"
#     key            = "prod/terraform.tfstate"
#     region         = "ap-southeast-1"
#     encrypt        = true
#     dynamodb_table = "terraform-state-lock"
#   }
# }
