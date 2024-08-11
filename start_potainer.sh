#!/bin/bash

# Create a Docker volume for Portainer data if it does not already exist
docker volume inspect portainer_data >/dev/null 2>&1 || docker volume create portainer_data

# Run the Portainer container
docker run -d -p 9000:9000 --name=portainer --restart=unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data portainer/portainer-ce

# Inform the user that Portainer is running
echo "Portainer is running and accessible at http://localhost:9000"
