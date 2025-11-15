# Curse Project - Docker Compose Setup

This repo groups several self-hosted services. Each service now lives in its own folder containing its Docker Compose file and a helper start script.

## Folder layout
- `portainer/` – Portainer UI (`docker-compose.portainer.yml`, `start_potainer.sh`)
- `bark/` – Bark push server (`docker-compose.bark.yml`, `start_bark.sh`)
- `duck-free/` – DuckCoding notifier (`docker-compose.duck-free.yml`, `start_duck_free.sh`, `duck-free-config/`)
- `mermaid/` – Mermaid Live Editor (`docker-compose.mermaid.yml`, `start_mermaid.sh`)
- `registry/` – Local Docker registry (`docker-compose.registry.yml`, `start_registry.sh`, `registry-config/`)
- `telemetry/` – OTEL collector + Prometheus + Grafana (`docker-compose.telemetry.yml`, `start_telemetry.sh`, `telemetry-config/`)
- `shrimp-task-manager/` – Shrimp Task Manager (`docker-compose.shrimp-task-manager.yml`, `start_shrimp_task_manager.sh`)
- Root helpers: `start_all.sh`, `stop_all.sh`, `init_docker_env.sh`, `update_fastest_mirror.sh`

## Quick start
- Start everything: `./start_all.sh`
- Stop everything: `./stop_all.sh`
- Start a single service (examples):
  - Portainer: `./portainer/start_potainer.sh`
  - Bark: `./bark/start_bark.sh`
  - Duck Free: `./duck-free/start_duck_free.sh`
  - Mermaid: `./mermaid/start_mermaid.sh`
  - Registry: `./registry/start_registry.sh`
  - Telemetry: `./telemetry/start_telemetry.sh`
  - Shrimp Task Manager: `./shrimp-task-manager/start_shrimp_task_manager.sh`

## Compose commands (pattern)
From the repo root you can run Compose directly with the file in each folder, e.g.:
```bash
docker compose -f portainer/docker-compose.portainer.yml up -d
docker compose -f bark/docker-compose.bark.yml logs
docker compose -f telemetry/docker-compose.telemetry.yml down
docker compose -f shrimp-task-manager/docker-compose.shrimp-task-manager.yml up -d
```

## Access URLs
- Portainer: http://localhost:8000 / http://localhost:9000 / https://localhost:9443
- Bark: http://localhost:8087
- Mermaid: http://localhost:8005
- Grafana: http://capy.lan:3000 (admin/admin)
- Prometheus: http://capy.lan:9090
- OTLP endpoints: gRPC `capy.lan:4317`, HTTP `capy.lan:4318`
- Registry: http://localhost:5000
- Shrimp Task Manager: http://localhost:9998

## Notes
- Config folders stay beside their Compose files, so relative paths inside the YAMLs still work.
- Start scripts resolve their own directory, so they work no matter where you run them from.
- If you add a new service, mirror this pattern: create a folder with `docker-compose.<name>.yml` and a `start_<name>.sh` that points at it.
