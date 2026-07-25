module "root" {
  source = "../.."

  project     = "topvnsport"
  environment = "staging"
  region      = "ap-southeast-1"

  tags = {
    team = "devops"
  }
}
