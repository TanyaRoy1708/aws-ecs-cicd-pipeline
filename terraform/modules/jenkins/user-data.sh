#!/bin/bash
set -e

# Install Docker
apt-get update -y
apt-get install -y docker.io
systemctl enable --now docker

# Set vm.max_map_count for SonarQube's Elasticsearch
sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" >> /etc/sysctl.conf

# Run SonarQube container
docker run -d --name sonarqube --restart unless-stopped \
  -p 9000:9000 \
  -v sonarqube_data:/opt/sonarqube/data \
  -v sonarqube_extensions:/opt/sonarqube/extensions \
  -v sonarqube_logs:/opt/sonarqube/logs \
  sonarqube:community

# Install Jenkins + Java 17
wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list
apt-get update -y
apt-get install -y openjdk-17-jdk jenkins
systemctl enable --now jenkins

# Allow Jenkins to run Docker commands
usermod -aG docker jenkins
systemctl restart jenkins
