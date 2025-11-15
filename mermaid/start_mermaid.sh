#!/bin/bash

# Start Mermaid Live Editor using Docker Compose
echo "Starting Mermaid Live Editor using Docker Compose..."

# Resolve directory of this script so it works from anywhere
SCRIPT_DIR="$(cd -- "$(dirname "$0")" && pwd)"

# Start Mermaid Live Editor service using its specific compose file
docker compose -f "$SCRIPT_DIR/docker-compose.mermaid.yml" up -d

# Check if Mermaid Live Editor started successfully
if [ $? -eq 0 ]; then
    echo "Mermaid Live Editor is running and accessible at http://localhost:8005"
    echo "Use 'docker compose -f $SCRIPT_DIR/docker-compose.mermaid.yml logs' to view logs"
    echo "Use 'docker compose -f $SCRIPT_DIR/docker-compose.mermaid.yml down' to stop Mermaid Live Editor"
else
    echo "Failed to start Mermaid Live Editor. Please check the Docker logs for more details."
    echo "Use 'docker compose -f $SCRIPT_DIR/docker-compose.mermaid.yml logs' to view logs"
fi
