#!/bin/sh

# Update the package index
sudo apt-get update

# Download the Docker installation script
curl -fsSL https://get.docker.com -o get-docker.sh

# Execute the Docker installation script
sudo sh ./get-docker.sh

# Add the docker group if it does not already exist
if ! getent group docker >/dev/null; then
    sudo groupadd docker
fi

# Add the current user to the docker group
sudo usermod -aG docker "$USER"

# Inform the user to log out and log back in
echo "Docker installation completed. Please log out and log back in to apply group changes."
