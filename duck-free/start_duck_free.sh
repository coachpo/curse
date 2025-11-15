#!/bin/bash

# Start Duck Free notifier using Docker Compose
echo "Starting Duck Free notifier using Docker Compose..."

# Resolve directory of this script so it works from anywhere
SCRIPT_DIR="$(cd -- "$(dirname "$0")" && pwd)"

if [ ! -f "$SCRIPT_DIR/duck-free-config/.env.duck-free" ]; then
    echo "Missing .env.duck-free file. Copy example.env to .env.duck-free and update BARK_KEY before starting."
    exit 1
fi

# Start Duck Free service using its specific compose file
docker compose -f "$SCRIPT_DIR/docker-compose.duck-free.yml" up -d

# Check if Duck Free started successfully
if [ $? -eq 0 ]; then
    echo "Duck Free notifier is running. Check logs with:"
    echo "  docker compose -f $SCRIPT_DIR/docker-compose.duck-free.yml logs"
    echo "Stop the service with:"
    echo "  docker compose -f $SCRIPT_DIR/docker-compose.duck-free.yml down"
else
    echo "Failed to start Duck Free. Please review the Docker logs."
    echo "Use 'docker compose -f $SCRIPT_DIR/docker-compose.duck-free.yml logs' to view logs"
fi
