#!/bin/bash

# Start LibreChat using Docker Compose
echo "Starting LibreChat using Docker Compose..."

# Check if LibreChat repository exists, if not clone it
if [ ! -d "LibreChat" ]; then
    echo "LibreChat repository not found. Cloning from GitHub..."
    git clone https://github.com/danny-avila/LibreChat.git
    
    if [ $? -ne 0 ]; then
        echo "Failed to clone LibreChat repository."
        exit 1
    fi
fi

# Navigate to LibreChat directory
cd LibreChat

# Create .env file from .env.example if it doesn't exist
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        echo "Creating .env file from .env.example..."
        cp .env.example .env
    else
        echo "Error: .env.example not found!"
        exit 1
    fi
else
    echo ".env file already exists, skipping creation."
fi

# Start LibreChat
echo "Starting LibreChat..."
docker compose up -d

# Check if LibreChat started successfully
if [ $? -eq 0 ]; then
    echo "LibreChat is running and accessible at http://localhost:3080"
    echo ""
    echo "Note: Edit LibreChat/.env to configure API keys and settings"
    echo ""
    echo "Useful commands (from LibreChat directory):"
    echo "  - View logs: docker compose logs"
    echo "  - Stop: docker compose down"
else
    echo "Failed to start LibreChat. Please check the Docker logs for more details."
    echo "Use 'docker compose logs' to view logs (from LibreChat directory)"
fi

# Return to original directory
cd ..

