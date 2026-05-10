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

source "amazon-ebs" "github_runner" {
  region        = var.aws_region
  instance_type = "t3.micro"
  subnet_id     = "subnet-0a68ace70934ab625"
  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm-*-x86_64-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }

    owners      = ["amazon"]
    most_recent = true
  }

  ssh_username = "ec2-user"

  ami_name = "github-runner-base-{{timestamp}}"

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