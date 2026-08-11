#!/bin/bash

# This script installs docker engine to redhat linux distribution. It installs docker engine, adds
# user to the docker group and starts the service.

sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io

# Enable and start docker service
sudo systemctl enable docker.service
sudo systemctl start docker.service

#Add user to docker group
sudo usermod -aG docker $USER
sudo chmod 666 /var/run/docker.sock