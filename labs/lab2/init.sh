#!/bin/bash

sudo apt-get update

# Install Linux Networking Tools
sudo apt install -y net-tools

# Install Docker
sudo apt-get install -y docker.io

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create a new directory
cd $HOME
mkdir cafe

# Download docker compose file
cd cafe
wget https://raw.githubusercontent.com/nginxinc/nginx-azure-workshops/main/labs/lab2/docker-compose.yml

# Run docker compose to create the containers
sudo docker-compose up -d