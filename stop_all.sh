#!/bin/bash

# Stop all services using Docker Compose
echo "Stopping all services using Docker Compose..."

# Stop Portainer
echo "Stopping Portainer..."
docker compose -f docker-compose.portainer.yml down

# Stop Bark
echo "Stopping Bark..."
docker compose -f docker-compose.bark.yml down

# Stop Duck Free notifier
echo "Stopping Duck Free notifier..."
docker compose -f docker-compose.duck-free.yml down

# Stop Mermaid Live Editor
echo "Stopping Mermaid Live Editor..."
docker compose -f docker-compose.mermaid.yml down

# Stop Droid2API
echo "Stopping Droid2API..."
docker compose -f docker-compose.droid2api.yml down

# Stop Telemetry
echo "Stopping Telemetry Stack..."
docker compose -f docker-compose.telemetry.yml down

echo "All services have been stopped."
