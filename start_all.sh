#!/bin/bash

# Start all services using Docker Compose
echo "Starting all services using Docker Compose..."

# Track overall success
status=0

# Start Portainer
echo "Starting Portainer..."
docker compose -f portainer/docker-compose.portainer.yml up -d || status=1

# Start Bark
echo "Starting Bark..."
docker compose -f bark/docker-compose.bark.yml up -d || status=1

# Start Duck Free notifier
echo "Starting Duck Free notifier..."
docker compose -f duck-free/docker-compose.duck-free.yml up -d || status=1

# Start Mermaid Live Editor
echo "Starting Mermaid Live Editor..."
docker compose -f mermaid/docker-compose.mermaid.yml up -d || status=1

# Start Telemetry
echo "Starting Telemetry Stack..."
docker compose -f telemetry/docker-compose.telemetry.yml up -d || status=1

# Start Shrimp Task Manager
echo "Starting Shrimp Task Manager..."
docker compose -f shrimp-task-manager/docker-compose.shrimp-task-manager.yml up -d || status=1

# Check if all services started successfully
if [ $status -eq 0 ]; then
    echo "All services are running! Access them at:"
    echo "  - Portainer: http://capy.lan:8000 or http://capy.lan:9000"
    echo "  - Bark Server: http://capy.lan:8087"
    echo "  - Duck Free notifier: see logs for announcements"
    echo "  - Mermaid Live Editor: http://capy.lan:8005"
    echo "  - Grafana Dashboard: http://capy.lan:3000 (admin/admin)"
    echo "  - Prometheus: http://capy.lan:9090"
    echo ""
    echo "Useful commands:"
    echo "  - View Portainer logs: docker compose -f portainer/docker-compose.portainer.yml logs"
    echo "  - View Bark logs: docker compose -f bark/docker-compose.bark.yml logs"
    echo "  - View Duck Free logs: docker compose -f duck-free/docker-compose.duck-free.yml logs"
    echo "  - View Mermaid Live Editor logs: docker compose -f mermaid/docker-compose.mermaid.yml logs"
    echo "  - View Telemetry logs: docker compose -f telemetry/docker-compose.telemetry.yml logs"
    echo "  - View Shrimp Task Manager logs: docker compose -f shrimp-task-manager/docker-compose.shrimp-task-manager.yml logs"
    echo "  - Stop Portainer: docker compose -f portainer/docker-compose.portainer.yml down"
    echo "  - Stop Bark: docker compose -f bark/docker-compose.bark.yml down"
    echo "  - Stop Duck Free: docker compose -f duck-free/docker-compose.duck-free.yml down"
    echo "  - Stop Mermaid Live Editor: docker compose -f mermaid/docker-compose.mermaid.yml down"
    echo "  - Stop Telemetry: docker compose -f telemetry/docker-compose.telemetry.yml down"
    echo "  - Stop Shrimp Task Manager: docker compose -f shrimp-task-manager/docker-compose.shrimp-task-manager.yml down"
    echo "  - Stop all: ./stop_all.sh"
else
    echo "Failed to start some services. Please check the Docker logs for more details."
fi

exit $status
