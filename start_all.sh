#!/bin/bash

# Start all services using Docker Compose
echo "Starting all services using Docker Compose..."

# Track overall success
status=0

# Start Portainer
echo "Starting Portainer..."
docker compose -f docker-compose.portainer.yml up -d || status=1

# Start Bark
echo "Starting Bark..."
docker compose -f docker-compose.bark.yml up -d || status=1

# Start Telemetry
echo "Starting Telemetry Stack..."
docker compose -f docker-compose.telemetry.yml up -d || status=1

# Check if all services started successfully
if [ $status -eq 0 ]; then
    echo "All services are running! Access them at:"
    echo "  - Portainer: http://capy.lan:8000 or http://capy.lan:9000"
    echo "  - Bark Server: http://capy.lan:8087"
    echo "  - Grafana Dashboard: http://capy.lan:3000 (admin/admin)"
    echo "  - Prometheus: http://capy.lan:9090"
    echo ""
    echo "Useful commands:"
    echo "  - View Portainer logs: docker compose -f docker-compose.portainer.yml logs"
    echo "  - View Bark logs: docker compose -f docker-compose.bark.yml logs"
    echo "  - View Telemetry logs: docker compose -f docker-compose.telemetry.yml logs"
    echo "  - Stop Portainer: docker compose -f docker-compose.portainer.yml down"
    echo "  - Stop Bark: docker compose -f docker-compose.bark.yml down"
    echo "  - Stop Telemetry: docker compose -f docker-compose.telemetry.yml down"
    echo "  - Stop all: ./stop_all.sh"
else
    echo "Failed to start some services. Please check the Docker logs for more details."
fi

exit $status
