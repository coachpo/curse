#!/bin/bash

# Start Shrimp Task Manager using Docker Compose
echo "Starting Shrimp Task Manager using Docker Compose..."

# Resolve directory of this script so it works from anywhere
SCRIPT_DIR="$(cd -- "$(dirname "$0")" && pwd)"

# Start the service using its specific compose file
docker compose -f "$SCRIPT_DIR/docker-compose.shrimp-task-manager.yml" up -d

# Check if it started successfully
if [ $? -eq 0 ]; then
    echo "Shrimp Task Manager is running at http://localhost:9998"
    echo "Logs: docker compose -f $SCRIPT_DIR/docker-compose.shrimp-task-manager.yml logs"
    echo "Stop: docker compose -f $SCRIPT_DIR/docker-compose.shrimp-task-manager.yml down"
else
    echo "Failed to start Shrimp Task Manager. Check Docker logs."
    echo "Use 'docker compose -f $SCRIPT_DIR/docker-compose.shrimp-task-manager.yml logs' to view logs"
fi
