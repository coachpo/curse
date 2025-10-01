#!/bin/bash

# Start all services using Docker Compose
echo "Starting all services using Docker Compose..."

# Start Portainer
echo "Starting Portainer..."
docker compose -f docker-compose.portainer.yml up -d

# Start Bark
echo "Starting Bark..."
docker compose -f docker-compose.bark.yml up -d

# Start LibreChat
echo "Starting LibreChat..."
docker compose -f docker-compose.librechat.yml up -d

# Check if all services started successfully
if [ $? -eq 0 ]; then
    echo "All services are running! Access them at:"
    echo "  - Portainer: http://localhost:8000 or http://localhost:9000"
    echo "  - Bark Server: http://localhost:8087"
    echo "  - LibreChat: http://localhost:3080"
    echo ""
    echo "Useful commands:"
    echo "  - View Portainer logs: docker compose -f docker-compose.portainer.yml logs"
    echo "  - View Bark logs: docker compose -f docker-compose.bark.yml logs"
    echo "  - View LibreChat logs: docker compose -f docker-compose.librechat.yml logs"
    echo "  - Stop Portainer: docker compose -f docker-compose.portainer.yml down"
    echo "  - Stop Bark: docker compose -f docker-compose.bark.yml down"
    echo "  - Stop LibreChat: docker compose -f docker-compose.librechat.yml down"
    echo "  - Stop all: ./stop_all.sh"
else
    echo "Failed to start some services. Please check the Docker logs for more details."
fi
