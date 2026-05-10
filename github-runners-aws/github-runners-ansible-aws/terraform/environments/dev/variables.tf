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
