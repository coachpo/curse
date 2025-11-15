#!/bin/bash

# Start Docker Registry using Docker Compose
echo "Starting Docker Registry using Docker Compose..."

# Resolve directory of this script so it works from anywhere
SCRIPT_DIR="$(cd -- "$(dirname "$0")" && pwd)"

# Start Registry service using its specific compose file
docker compose -f "$SCRIPT_DIR/docker-compose.registry.yml" up -d

# Check if Registry started successfully
if [ $? -eq 0 ]; then
    echo "Docker Registry is running and accessible at http://localhost:5000"
    echo "Registry is configured as a cache/transit hub for Docker images"
    echo ""
    echo "Usage examples:"
    echo "  - List images: curl http://localhost:5000/v2/_catalog"
    echo "  - Push image: docker tag myimage:latest localhost:5000/myimage:latest && docker push localhost:5000/myimage:latest"
    echo "  - Pull image: docker pull localhost:5000/myimage:latest"
    echo ""
    echo "Management commands:"
    echo "  - View logs: docker compose -f $SCRIPT_DIR/docker-compose.registry.yml logs"
    echo "  - Stop registry: docker compose -f $SCRIPT_DIR/docker-compose.registry.yml down"
    echo "  - View volumes: docker volume ls | grep registry"
else
    echo "Failed to start Docker Registry. Please check the Docker logs for more details."
    echo "Use 'docker compose -f $SCRIPT_DIR/docker-compose.registry.yml logs' to view logs"
fi
