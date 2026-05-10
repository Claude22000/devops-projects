resource "aws_db_instance" "rds_instance" {
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "sonarqube_db"
  engine                 = "postgres"
  engine_version         = "16.3"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.ec2.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "sonarqube-rds-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "sonarqube-rds-subnet-group"
  }
}

