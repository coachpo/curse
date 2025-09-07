#!/bin/bash

# Start Bark Server using Docker Compose
echo "Starting Bark Server using Docker Compose..."

# Start Bark service using its specific compose file
docker compose -f docker-compose.bark.yml up -d

# Check if Bark started successfully
if [ $? -eq 0 ]; then
    echo "Bark Server is running and accessible at http://localhost:8087"
    echo "Use 'docker compose -f docker-compose.bark.yml logs' to view logs"
    echo "Use 'docker compose -f docker-compose.bark.yml down' to stop Bark"
else
    echo "Failed to start Bark. Please check the Docker logs for more details."
    echo "Use 'docker compose -f docker-compose.bark.yml logs' to view logs"
fi
