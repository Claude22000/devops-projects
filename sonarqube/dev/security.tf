data "aws_vpc" "main" {
  default = true
}

resource "aws_security_group" "ec2" {
    name = "sonarqube_sg"
    description = "Security group for SonarQube EC2 instance"
    vpc_id = data.aws_vpc.main.id
}

resource "aws_vpc_security_group_egress_rule" "ec2_allow_all_outbound" {
    security_group_id = aws_security_group.ec2.id
    ip_protocol = "-1"
    cidr_ipv4 = "0.0.0.0/0"

}

resource "aws_vpc_security_group_ingress_rule" "ec2_allow_all_inbound" {
    security_group_id = aws_security_group.ec2.id
    ip_protocol = "TCP"
    from_port = 9000
    to_port = 9000
    cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.ec2.id

  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22

  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.ec2.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}