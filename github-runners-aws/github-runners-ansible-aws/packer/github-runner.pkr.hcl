packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
  }
}

variable "aws_region" {
  default = "us-east-1"
}
# variable "github_actions_cidrs" {
#   type = list(string)
# }

source "amazon-ebs" "github_runner" {
  region        = var.aws_region
  instance_type = "t2.medium"
  subnet_id     = "subnet-072eb424eebedf6e9"

  associate_public_ip_address = true
  temporary_security_group_source_cidrs = ["0.0.0.0/0"]
  # temporary_security_group_source_cidrs = var.github_actions_cidrs

  ssh_username = "ec2-user"
  ami_name     = "github-runner-base-{{timestamp}}"

  source_ami_filter {
    filters = {
      name                = "al2023-ami-*-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }

    owners      = ["amazon"]
    most_recent = true
  }

  tags = {
    Name        = "github-runner-base"
    Environment = "dev"
    CreatedBy   = "packer"
  }
}

build {
  sources = ["source.amazon-ebs.github_runner"]

  provisioner "ansible" {
    playbook_file = "./ansible/playbook.yaml"
  }
}