#!/bin/bash

# Start OpenList using Docker Compose
echo "Starting OpenList using Docker Compose..."

# Resolve directory of this script so it works from anywhere
SCRIPT_DIR="$(cd -- "$(dirname "$0")" && pwd)"

# Start OpenList service using its specific compose file
docker compose -f "$SCRIPT_DIR/docker-compose.openlist.yml" up -d

# Check if OpenList started successfully
if [ $? -eq 0 ]; then
    echo "OpenList is running and accessible at http://localhost:5244"
    echo "Use 'docker compose -f $SCRIPT_DIR/docker-compose.openlist.yml logs' to view logs"
    echo "Use 'docker compose -f $SCRIPT_DIR/docker-compose.openlist.yml down' to stop OpenList"
else
    echo "Failed to start OpenList. Please check the Docker logs for more details."
    echo "Use 'docker compose -f $SCRIPT_DIR/docker-compose.openlist.yml logs' to view logs"
fi
