
module "network" {
  source = "../../modules/network"
}

module "github_runner" {
  source = "../../modules/github-runner"
  instance_type      = var.instance_type
  runner_count       = var.runner_count
}

data "aws_caller_identity" "current" {}

