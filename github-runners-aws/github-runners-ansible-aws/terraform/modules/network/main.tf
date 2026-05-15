data "aws_vpc" "default" {
  default = true
}

# data "aws_subnets" "default" {
#   filter {
#     name   = "tag:Name"
#     values = ["public-subnet"]
#   }
# }

# data "aws_security_group" "github_runner_sg" {
#   name        = "github-runner-sg"
#   vpc_id = data.aws_vpc.default.id
# }

# data "aws_vpc_security_group_egress_rule" "ec2_allow_all_outbound" {
#     security_group_id = data.aws_security_group.github_runner_sg.id
#     ip_protocol = "-1"
#     cidr_ipv4 = "0.0.0.0/0"
# }

# data "aws_vpc_security_group_ingress_rule" "allow_ssh" {
#   security_group_id = data.aws_security_group.github_runner_sg.id

#   ip_protocol = "tcp"
#   from_port   = 22
#   to_port     = 22

#   cidr_ipv4 = "0.0.0.0/0"
#   }

  