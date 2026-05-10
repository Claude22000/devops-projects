#!/bin/bash

set -e

# Update system
sudo yum update -y

# Install Docker
sudo yum install -y docker

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add ec2-user to docker group
sudo usermod -aG docker ec2-user

# Increase vm.max_map_count required by Elasticsearch/SonarQube
sudo sysctl -w vm.max_map_count=524288
echo "vm.max_map_count=524288" | sudo tee -a /etc/sysctl.conf

# Increase file descriptor limits
echo "fs.file-max=131072" | sudo tee -a /etc/sysctl.conf

# Create SonarQube container
sudo docker run -d \
  --name sonarqube \
  --restart unless-stopped \
  -p 9000:9000 \
  -e SONAR_JDBC_URL=jdbc:postgresql://${rds_endpoint}:5432/sonarqube_db \
  -e SONAR_JDBC_USERNAME=${db_username} \
  -e SONAR_JDBC_PASSWORD=${db_password} \
  sonarqube:lts-community