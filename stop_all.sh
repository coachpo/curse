#!/bin/bash

# Stop all services using Docker Compose
echo "Stopping all services using Docker Compose..."

# Stop Portainer
echo "Stopping Portainer..."
docker compose -f docker-compose.portainer.yml down

# Stop Bark
echo "Stopping Bark..."
docker compose -f docker-compose.bark.yml down

# Stop LibreChat
echo "Stopping LibreChat..."
if [ -d "LibreChat" ]; then
    cd LibreChat
    docker compose down
    cd ..
fi

echo "All services have been stopped."
