#!/bin/bash

# Start Portainer using Docker Compose
echo "Starting Portainer using Docker Compose..."

# Resolve directory of this script so it works from anywhere
SCRIPT_DIR="$(cd -- "$(dirname "$0")" && pwd)"

# Start Portainer service using its specific compose file
docker compose -f "$SCRIPT_DIR/docker-compose.portainer.yml" up -d

# Check if Portainer started successfully
if [ $? -eq 0 ]; then
    echo "Portainer is running and accessible at:"
    echo "  - http://localhost:8000 (HTTP)"
    echo "  - http://localhost:9000 (HTTP)"
    echo "  - https://localhost:9443 (HTTPS)"
    echo "Use 'docker compose -f $SCRIPT_DIR/docker-compose.portainer.yml logs' to view logs"
    echo "Use 'docker compose -f $SCRIPT_DIR/docker-compose.portainer.yml down' to stop Portainer"
else
    echo "Failed to start Portainer. Please check the Docker logs for more details."
    echo "Use 'docker compose -f $SCRIPT_DIR/docker-compose.portainer.yml logs' to view logs"
fi
