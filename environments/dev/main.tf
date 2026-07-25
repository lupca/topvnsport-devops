module "root" {
  source = "../.."

  project     = "topvnsport"
  environment = "dev"
  region      = "ap-southeast-1"

  tags = {
    team = "devops"
  }
}
