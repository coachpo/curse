#!/bin/bash

# Start Telemetry Stack using Docker Compose
echo "Starting Telemetry Stack using Docker Compose..."

# Resolve directory of this script so it works from anywhere
SCRIPT_DIR="$(cd -- "$(dirname "$0")" && pwd)"

# Start Telemetry services using its specific compose file
docker compose -f "$SCRIPT_DIR/docker-compose.telemetry.yml" up -d

# Check if Telemetry started successfully
if [ $? -eq 0 ]; then
    echo "Telemetry Stack is running! Access the services at:"
    echo "  - Grafana Dashboard: http://capy.lan:3000 (admin/admin)"
    echo "  - Prometheus: http://capy.lan:9090"
    echo ""
    echo "OTLP Endpoints (for metrics):"
    echo "  - gRPC: capy.lan:4317"
    echo "  - HTTP: capy.lan:4318"
    echo ""
    echo "Management commands:"
    echo "  - View logs: docker compose -f $SCRIPT_DIR/docker-compose.telemetry.yml logs"
    echo "  - Stop telemetry: docker compose -f $SCRIPT_DIR/docker-compose.telemetry.yml down"
    echo "  - View volumes: docker volume ls | grep telemetry"
else
    echo "Failed to start Telemetry Stack. Please check the Docker logs for more details."
    echo "Use 'docker compose -f $SCRIPT_DIR/docker-compose.telemetry.yml logs' to view logs"
fi
