#!/bin/bash

echo "Starting Spear using Docker Compose..."

SCRIPT_DIR="$(cd -- "$(dirname "$0")" && pwd)"

COMPOSE_FILE="$SCRIPT_DIR/docker-compose.spear.yml"

ENV_ARGS=()
if [ -f "$SCRIPT_DIR/.env" ]; then
  ENV_ARGS+=(--env-file "$SCRIPT_DIR/.env")
else
  echo "Note: $SCRIPT_DIR/.env not found; using compose defaults."
  echo "      Copy $SCRIPT_DIR/.env.example to $SCRIPT_DIR/.env to customize images/secrets."
fi

COMPOSE_DISABLE_ENV_FILE=1 docker compose \
  --project-directory "$SCRIPT_DIR" \
  "${ENV_ARGS[@]}" \
  -f "$COMPOSE_FILE" \
  up -d

if [ $? -eq 0 ]; then
  echo "Spear is running and accessible at:"
  echo "  - Frontend: http://localhost:13000"
  echo "  - Backend:  http://localhost:18000 (health: /healthz)"
  echo "Use 'docker compose --project-directory $SCRIPT_DIR -f $COMPOSE_FILE logs -f' to view logs"
  echo "Use 'docker compose --project-directory $SCRIPT_DIR -f $COMPOSE_FILE down' to stop Spear"
else
  echo "Failed to start Spear. Please check the Docker logs for more details."
  echo "Use 'docker compose --project-directory $SCRIPT_DIR -f $COMPOSE_FILE logs' to view logs"
fi
