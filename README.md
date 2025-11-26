# Curse Compose Stack

Self-hosted services packaged as separate Docker Compose bundles, each with its own start script and config folder (if needed).

## Prerequisites
- Docker + Docker Compose v2 on the host.
- Free ports: 3000, 4317, 4318, 5000, 8000, 8005, 8087, 9000, 9443, 9998, 13133, 8889, 9090.
- (Duck Free) Copy `duck-free/duck-free-config/example.env` to `duck-free/duck-free-config/.env.duck-free` and fill your Bark credentials.

## How to run
- Start a service with its helper script (runs from any directory):
  - Portainer: `./portainer/start_potainer.sh`
  - Bark: `./bark/start_bark.sh`
  - Duck Free: `./duck-free/start_duck_free.sh`
  - Mermaid: `./mermaid/start_mermaid.sh`
  - Registry: `./registry/start_registry.sh`
  - Telemetry stack: `./telemetry/start_telemetry.sh`
  - Shrimp Task Manager: `./shrimp-task-manager/start_shrimp_task_manager.sh`
- Or use Compose directly from repo root: `docker compose -f <folder>/docker-compose.<name>.yml up -d`
- Stop a service: `docker compose -f <folder>/docker-compose.<name>.yml down`
- View logs: `docker compose -f <folder>/docker-compose.<name>.yml logs -f`

## Services at a glance
| Service | Purpose | Start file | Default URL/Port | Config |
| --- | --- | --- | --- | --- |
| Portainer | Docker management UI | `portainer/start_potainer.sh` | http://localhost:8000 / 9000, https://localhost:9443 | Volume `portainer_data` |
| Bark | iOS push gateway | `bark/start_bark.sh` | http://localhost:8087 | — |
| Duck Free | DuckCoding availability notifier (uses Bark) | `duck-free/start_duck_free.sh` | (no exposed port) | `duck-free/duck-free-config/.env.duck-free` |
| Mermaid Live Editor | Diagram editor | `mermaid/start_mermaid.sh` | http://localhost:8005 | — |
| Registry | Local Docker registry | `registry/start_registry.sh` | http://localhost:5000 | `registry/registry-config/config.yml`, volume `registry-data` |
| Telemetry | OTEL collector + Prometheus + Grafana | `telemetry/start_telemetry.sh` | Grafana http://capy.lan:3000 (admin/admin); Prometheus http://capy.lan:9090; OTLP gRPC capy.lan:4317; OTLP HTTP capy.lan:4318 | `telemetry/telemetry-config/*`, volumes `prometheus-data`, `grafana-data` |
| Shrimp Task Manager | Task manager UI/API | `shrimp-task-manager/start_shrimp_task_manager.sh` | http://localhost:9998 | Volume `shrimp_data` |

## Configuration notes
- Config folders sit beside their Compose files, so relative paths in YAML stay valid.
- Telemetry stack:
  - `telemetry-config/otel-collector-config.yaml` sets endpoints and resource attributes (host defaults to `capy.lan`).
  - `telemetry-config/prometheus.yml` scrapes the collector; adjusts labels/targets as needed.
  - `telemetry-config/grafana-datasources.yml` wires Grafana to Prometheus; default Grafana creds `admin/admin`.
- Duck Free: `.env.duck-free` must be created from the example before starting.
- Registry: delete enabled via `REGISTRY_STORAGE_DELETE_ENABLED=true`; data persisted in `registry-data`.
- Volumes persist between restarts; remove with `docker volume rm <name>` if you want a clean slate.

## Troubleshooting
- Check status: `docker compose -f <folder>/docker-compose.<name>.yml ps`
- Follow logs: `docker compose -f <folder>/docker-compose.<name>.yml logs -f`
- Restart a service: `docker compose -f <folder>/docker-compose.<name>.yml up -d --force-recreate`
- Ports in use: stop conflicting local services or change host bindings in the compose files.
- ARM note: Mermaid image is pinned to `linux/arm64`; adjust `platform` if running on x86_64.

## Contributing / extending
- To add a new service, mirror the pattern: a folder with `docker-compose.<name>.yml`, an optional config subfolder, and a `start_<name>.sh` that resolves its own directory.
