#!/bin/bash

# Start Droid2API using Docker Compose
echo "Starting Droid2API using Docker Compose..."

docker compose -f docker-compose.droid2api.yml up -d

if [ $? -eq 0 ]; then
    echo "Droid2API is running and accessible at http://localhost:3100"
    echo "Use 'docker compose -f docker-compose.droid2api.yml logs' to view logs"
    echo "Use 'docker compose -f docker-compose.droid2api.yml down' to stop Droid2API"
else
    echo "Failed to start Droid2API. Please check the Docker logs for more details."
    echo "Use 'docker compose -f docker-compose.droid2api.yml logs' to view logs"
fi
