variable "db_username" {
  description = "Master username for the SonarQube RDS instance"
  type        = string
}

variable "db_password" {
  description = "Master password for the SonarQube RDS instance"
  type        = string
  sensitive   = true
}

variable "subnet_id" {
  description = "Subnet ID to launch the SonarQube EC2 instance into"
  type        = string
}

variable "db_subnet_ids" {
  description = "Subnet IDs for the RDS DB subnet group"
  type        = list(string)
}
