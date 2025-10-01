#!/bin/bash

# Start LibreChat using Docker Compose
echo "Starting LibreChat using Docker Compose..."

# Create directories for LibreChat data and logs if they don't exist
mkdir -p librechat_data librechat_logs

# Start LibreChat service using its specific compose file
docker compose -f docker-compose.librechat.yml up -d

# Check if LibreChat started successfully
if [ $? -eq 0 ]; then
    echo "LibreChat is running and accessible at http://localhost:3080"
    echo "Use 'docker compose -f docker-compose.librechat.yml logs' to view logs"
    echo "Use 'docker compose -f docker-compose.librechat.yml down' to stop LibreChat"
else
    echo "Failed to start LibreChat. Please check the Docker logs for more details."
    echo "Use 'docker compose -f docker-compose.librechat.yml logs' to view logs"
fi

