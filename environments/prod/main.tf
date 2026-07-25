module "root" {
  source = "../.."

  project     = "topvnsport"
  environment = "prod"
  region      = "ap-southeast-1"

  tags = {
    team = "devops"
  }
}
