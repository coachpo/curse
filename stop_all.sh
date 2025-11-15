#!/bin/bash

# Stop all services using Docker Compose
echo "Stopping all services using Docker Compose..."

# Stop Portainer
echo "Stopping Portainer..."
docker compose -f portainer/docker-compose.portainer.yml down

# Stop Bark
echo "Stopping Bark..."
docker compose -f bark/docker-compose.bark.yml down

# Stop Duck Free notifier
echo "Stopping Duck Free notifier..."
docker compose -f duck-free/docker-compose.duck-free.yml down

# Stop Mermaid Live Editor
echo "Stopping Mermaid Live Editor..."
docker compose -f mermaid/docker-compose.mermaid.yml down

# Stop Telemetry
echo "Stopping Telemetry Stack..."
docker compose -f telemetry/docker-compose.telemetry.yml down

# Stop Shrimp Task Manager
echo "Stopping Shrimp Task Manager..."
docker compose -f shrimp-task-manager/docker-compose.shrimp-task-manager.yml down

echo "All services have been stopped."
