
module "network" {
  source = "../../modules/network"
}

module "github_runner" {
  source = "../../modules/github-runner"
  ami                = var.ami
  instance_type      = var.instance_type
  runner_count       = var.runner_count
  security_group_id  = module.network.security_group_id
}

data "aws_caller_identity" "current" {}

