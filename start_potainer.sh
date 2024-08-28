#!/bin/bash

# Set variables for reuse
VOLUME_NAME="portainer_data"
CONTAINER_NAME="portainer"
IMAGE_NAME="portainer/portainer-ce:2.21.0"
HOST_PORT="9000"
SSL_PORT="9443"
DOCKER_SOCK="/var/run/docker.sock"

# Create a Docker volume for Portainer data if it does not already exist
if ! docker volume inspect "$VOLUME_NAME" >/dev/null 2>&1; then
    docker volume create "$VOLUME_NAME"
    echo "Docker volume '$VOLUME_NAME' created."
else
    echo "Docker volume '$VOLUME_NAME' already exists."
fi

# Run the Portainer container
docker run -d \
  -p "$HOST_PORT:9000" \
  -p "$SSL_PORT:9443" \
  --name="$CONTAINER_NAME" \
  --restart=always \
  -v "$DOCKER_SOCK:$DOCKER_SOCK" \
  -v "$VOLUME_NAME:/data" \
  "$IMAGE_NAME"

# Check if the Portainer container started successfully
if [ $? -eq 0 ]; then
    echo "Portainer is running and accessible at http://localhost:$HOST_PORT"
else
    echo "Failed to start Portainer. Please check the Docker logs for more details."
fi
