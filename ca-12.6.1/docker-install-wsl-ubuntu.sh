#!/bin/bash
set -Eeuo pipefail
# This script installs docker engine to ubuntu linux distribution. It removes docker engine if already installed,
# then installs docker engine, adds logged in user to the docker group and starts the service.

# Remove Docker if already installed
sudo apt-get remove -y docker || true
sudo apt-get remove -y docker-engine || true
sudo apt-get remove -y docker.io || true
sudo apt-get remove -y containerd || true
sudo apt-get remove -y runc || true
sudo apt-get remove -y docker-ce || true
sudo apt-get remove -y docker-ce-cli || true
sudo apt-get remove -y containerd.io || true
sudo apt-get remove -y docker-compose-plugin || true

# set iptables to legacy
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy


# Install latest version of Docker
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
#Restrict to a particular version
#VERSION_STRING=5:20.10.22~3-0~ubuntu-jammy
#sudo apt-get install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-compose-plugin

#sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Enable and start docker service
sudo service docker start
sudo service docker status

# Check if Docker Service is running
sudo ps aux | grep docker
if [ $? -eq 0 ]; then
    echo "Docker installation is successful"
else
    echo "Docker Service is not running, Run Ubuntu WSL in Administrator mode and execute \$ sudo systemctl start docker.service"
fi

# Create docker group and assign logged in user to the group
sudo groupadd docker || true
sudo usermod -aG docker $(whoami) || true
echo "Logged in user added to the docker group. Docker commands available to execute...."
newgrp docker