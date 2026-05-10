terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

data "aws_secretsmanager_secret" "github_pat" {
  name = "GITHUB_RUNNERS_PUBLIC_KEY"
}

data "aws_secretsmanager_secret_version" "github_pat" {
  secret_id = data.aws_secretsmanager_secret.github_pat.id
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "tag:Name"
    values = ["public-subnet"]
  }
}

data "aws_security_group" "github_runner_sg" {
  name   = "github-runner-sg"
  vpc_id = data.aws_vpc.default.id
}

data "aws_ami" "github_runner" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["github-runner-base-*"]
  }
}

data "aws_key_pair" "github_runner_key" {
  key_name = "github-runner-key-v2"
}

data "aws_secretsmanager_secret" "github_runner_private_key" {
  name = "github-runner-private-key-v2"
}

data "aws_secretsmanager_secret_version" "github_runner_private_key" {
  secret_id = data.aws_secretsmanager_secret.github_runner_private_key.id
}

resource "aws_instance" "github_runner" {
  count = var.runner_count

  ami                         = data.aws_ami.github_runner.id
  instance_type               = var.instance_type
  subnet_id                   = "subnet-072eb424eebedf6e9"
  associate_public_ip_address = true

  key_name = data.aws_key_pair.github_runner_key.key_name

  vpc_security_group_ids = [
    data.aws_security_group.github_runner_sg.id
  ]

  user_data = templatefile(
    "${path.module}/install_github_runner.sh",
    {
      GITHUB_PAT     = data.aws_secretsmanager_secret_version.github_pat.secret_string
      RUNNER_VERSION = "2.328.0"

      GITHUB_OWNER = "Claude22000"
      GITHUB_REPO  = "github-runners"

      RUNNER_NAME   = "ec2-runner"
      RUNNER_LABELS = "standard"

      RUNNER_USER = "github-runner"
      RUNNER_DIR  = "/opt/actions-runner"
    }
  )

  tags = {
    Name = "GitHub Runner"
  }
}