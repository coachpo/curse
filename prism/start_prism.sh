#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.prism.yml"

ENV_ARGS=()
if [ -f "$SCRIPT_DIR/.env" ]; then
  ENV_ARGS+=(--env-file "$SCRIPT_DIR/.env")
  echo "Using environment file: $SCRIPT_DIR/.env"
else
  echo "Note: $SCRIPT_DIR/.env not found; using defaults from docker-compose.prism.yml."
  echo "      Copy $SCRIPT_DIR/env.example to $SCRIPT_DIR/.env to override image tags and ports."
fi

COMPOSE_ARGS=(--project-directory "$SCRIPT_DIR" "${ENV_ARGS[@]}" -f "$COMPOSE_FILE")

run_compose() {
  COMPOSE_DISABLE_ENV_FILE=1 docker compose "${COMPOSE_ARGS[@]}" "$@"
}

echo "Starting Prism using Docker Compose..."
if ! run_compose up -d; then
  echo "Failed to start Prism. Please check Docker logs."
  echo "Use \"docker compose --project-directory $SCRIPT_DIR -f $COMPOSE_FILE logs\" to inspect."
  exit 1
fi

echo "Prism is running:"
echo "  - Frontend: http://localhost:3000 (default; override with FRONTEND_PORT in prism/.env)"
echo "  - Backend:  http://localhost:8000 (default; override with BACKEND_PORT in prism/.env)"
echo "Use \"docker compose --project-directory $SCRIPT_DIR -f $COMPOSE_FILE ps\" to check status"
echo "Use \"docker compose --project-directory $SCRIPT_DIR -f $COMPOSE_FILE logs -f\" to stream logs"
