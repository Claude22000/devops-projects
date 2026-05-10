# modules/github-runner/variables.tf

variable "ami" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "runner_count" {
  type = number
}

variable "security_group_id" {
  description = "The security group ID for the GitHub Runner instances"
  type        = string
}