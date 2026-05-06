resource "aws_instance" "sonarqube" {
  ami                    = "ami-0eb38b817b93460ac" # free tier ami
  instance_type          = "t3.medium"
  subnet_id              = var.subnet_id
  user_data              = templatefile("${path.module}/sonar_script.sh", {
    rds_endpoint = aws_db_instance.rds_instance.address
    db_username  = var.db_username
    db_password  = var.db_password
  })
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = "sonarqube_key"

  tags = {
    Name = "sonarqube"
  }
}

resource "aws_eip" "app_eip" {
  domain = "vpc"
  region = "us-east-1"
}

resource "aws_eip_association" "app_eip_assoc" {
    // here we associate elastic ip to ec2 instance
    // instance id is the id of the ec2 instance
    instance_id = aws_instance.sonarqube.id

    // allocation id is the id of the elastic ip
    allocation_id = aws_eip.app_eip.id 
}

