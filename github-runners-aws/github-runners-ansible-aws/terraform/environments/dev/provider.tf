terraform{
  required_version = ">= 1.1.5"
  required_providers {
    datadog = {
      source = "datadog/datadog"
      version = "~> 3.0"
    }
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

data "aws_secretsmanager_secret" "datadog_api_key" {
  name = "DATADOG_API_KEY"
}

data "aws_secretsmanager_secret_version" "datadog_api_key" {
  secret_id = data.aws_secretsmanager_secret.datadog_api_key.id
}

data "aws_secretsmanager_secret" "datadog_app_key" {
  name = "DATADOG_APP_KEY"
}

data "aws_secretsmanager_secret_version" "datadog_app_key" {
  secret_id = data.aws_secretsmanager_secret.datadog_app_key.id
}

provider "aws" {
  region = "us-east-1"
}

provider "datadog" {
  api_key = data.aws_secretsmanager_secret_version.datadog_api_key.secret_string
  app_key = data.aws_secretsmanager_secret_version.datadog_app_key.secret_string
}

