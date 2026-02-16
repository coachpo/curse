#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.spear.yml"

ENV_ARGS=()
if [ -f "$SCRIPT_DIR/.env" ]; then
  ENV_ARGS+=(--env-file "$SCRIPT_DIR/.env")
  echo "Using environment file: $SCRIPT_DIR/.env"
else
  echo "Note: $SCRIPT_DIR/.env not found; using defaults from docker-compose.spear.yml."
  echo "      Copy $SCRIPT_DIR/.env.example to $SCRIPT_DIR/.env to set BACKEND_IMAGE, FRONTEND_IMAGE, DB creds, and secrets."
fi

COMPOSE_ARGS=(--project-directory "$SCRIPT_DIR" "${ENV_ARGS[@]}" -f "$COMPOSE_FILE")

run_compose() {
  COMPOSE_DISABLE_ENV_FILE=1 docker compose "${COMPOSE_ARGS[@]}" "$@"
}

echo "Stopping running Spear containers..."
if ! run_compose down --remove-orphans; then
  echo "Failed to stop existing Spear containers."
  echo "Use \"docker compose --project-directory $SCRIPT_DIR -f $COMPOSE_FILE logs\" to inspect."
  exit 1
fi

echo "Re-pulling Spear images (db, backend, worker, frontend)..."
if ! run_compose pull; then
  echo "Failed to pull one or more images."
  echo "Check BACKEND_IMAGE and FRONTEND_IMAGE in $SCRIPT_DIR/.env (or defaults in .env.example)."
  exit 1
fi

echo "Redeploying Spear containers..."
if ! run_compose up -d --force-recreate --remove-orphans; then
  echo "Failed to redeploy Spear."
  echo "Use \"docker compose --project-directory $SCRIPT_DIR -f $COMPOSE_FILE logs\" to inspect."
  exit 1
fi

echo "Spear is deployed:"
echo "  - Frontend: http://localhost:3100"
echo "  - Backend:  http://localhost:8100 (health: /healthz)"
echo "  - Services: db, backend, worker, frontend"
echo "Use \"docker compose --project-directory $SCRIPT_DIR -f $COMPOSE_FILE ps\" to check status"
echo "Use \"docker compose --project-directory $SCRIPT_DIR -f $COMPOSE_FILE logs -f\" to stream logs"
