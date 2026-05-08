# environments/dev/variables.tf

variable "ami" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "runner_count" {
  type = number
}

variable "datadog_external_id" {
  description = "External ID required by Datadog when assuming the AWS integration role"
  type        = string
  default     = "datadog-external-id"
}