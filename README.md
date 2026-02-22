# Curse Compose Stack

Self-hosted services packaged as separate Docker Compose bundles. All ports are configurable via environment variables. Services are auto-discovered by the Makefile.

## Prerequisites
- Docker + Docker Compose v2 on the host.
- (Duck Free) Copy `duck-free/duck-free-config/example.env` to `duck-free/duck-free-config/.env.duck-free` and fill your Bark credentials.
- (Spear) Copy `spear/env.example` to `spear/.env` and fill in real values (`GHCR_OWNER`, `DJANGO_SECRET_KEY`, `JWT_SIGNING_KEY`, etc.).

## How to run

### Using Make (recommended)
```bash
make start-<service>     # Start a single service
make stop-<service>      # Stop a single service
make restart-<service>   # Restart a single service
make logs-<service>      # Tail logs
make start-all           # Start everything
make stop-all            # Stop everything
make status              # Show running containers
make ports               # Show port assignments
make services            # List discovered services
```

### Using Compose directly
Each service has a `compose.yml` in its directory:
```bash
cd <service> && docker compose up -d
cd <service> && docker compose down
cd <service> && docker compose logs -f

# Or from repo root:
docker compose -f <service>/compose.yml up -d
```

## Services at a glance
| Service | Purpose | Default URL/Port | Config |
| --- | --- | --- | --- |
| Portainer | Docker management UI | http://localhost:9000, https://localhost:9443 (edge: 8001) | Volume `portainer_data` |
| Bark | iOS push gateway | http://localhost:8087 | — |
| Duck Free | DuckCoding availability notifier (uses Bark) | (no exposed port) | `duck-free/duck-free-config/.env.duck-free` |
| Mermaid Live Editor | Diagram editor | http://localhost:8005 | — |
| Registry | Local Docker registry | http://localhost:5000 | `registry/registry-config/config.yml`, volume `registry-data` |
| Spear | Beacon Spear (Caddy → Django backend + worker + React frontend) | http://localhost:80, https://localhost:443 | `spear/.env` (copy from `spear/env.example`), `spear/Caddyfile` |
| Prism | Prism app (backend + frontend) | http://localhost:3000 (frontend), http://localhost:8000 (backend) | `prism/.env` (optional, copy from `prism/env.example`) |
| Telemetry | OTEL collector + Prometheus + Grafana | Grafana http://localhost:3001; Prometheus http://localhost:9090; OTLP gRPC :4317; OTLP HTTP :4318 | `telemetry/telemetry-config/*`, volumes `prometheus-data`, `grafana-data` |

## Default port map

All ports are overridable via environment variables in each service's `.env` file or shell environment.

| Port | Service | Env var |
|------|---------|---------|
| 80   | Spear (Caddy HTTP) | `SPEAR_HTTP_PORT` |
| 443  | Spear (Caddy HTTPS + HTTP/3) | `SPEAR_HTTPS_PORT` |
| 3000 | Prism frontend | `PRISM_FRONTEND_PORT` |
| 3001 | Grafana | `GRAFANA_PORT` |
| 4317 | OTLP gRPC | `OTLP_GRPC_PORT` |
| 4318 | OTLP HTTP | `OTLP_HTTP_PORT` |
| 5000 | Docker Registry | `REGISTRY_PORT` |
| 8000 | Prism backend | `PRISM_BACKEND_PORT` |
| 8001 | Portainer edge | `PORTAINER_EDGE_PORT` |
| 8005 | Mermaid | `MERMAID_PORT` |
| 8087 | Bark | `BARK_PORT` |
| 8889 | OTEL Prometheus exporter | `OTEL_METRICS_PORT` |
| 9000 | Portainer UI | `PORTAINER_PORT` |
| 9090 | Prometheus | `PROMETHEUS_PORT` |
| 9443 | Portainer HTTPS | `PORTAINER_HTTPS_PORT` |
| 13133 | OTEL health check | `OTEL_HEALTH_PORT` |

## Configuration notes
- Config folders sit beside their Compose files, so relative paths in YAML stay valid.
- Telemetry stack:
  - `telemetry-config/otel-collector-config.yaml` sets endpoints and resource attributes (host defaults to `capy.lan`).
  - `telemetry-config/prometheus.yml` scrapes the collector; adjusts labels/targets as needed.
  - `telemetry-config/grafana-datasources.yml` wires Grafana to Prometheus; default Grafana creds `admin/admin`.
- Duck Free: `.env.duck-free` must be created from the example before starting.
- Registry: delete enabled via `REGISTRY_STORAGE_DELETE_ENABLED=true`; data persisted in `registry-data`.
- Prism: to override image tags or ports, copy `prism/env.example` to `prism/.env` and edit values.
- Spear: Caddy handles TLS termination and reverse-proxies to internal backend (:8100) and frontend (:3100). Backend and frontend ports are not exposed to the host. Copy `spear/env.example` to `spear/.env` and replace all `change-me` placeholders before starting.
- Volumes persist between restarts; remove with `docker volume rm <name>` if you want a clean slate.

## Troubleshooting
- Check status: `make status` or `docker compose -f <service>/compose.yml ps`
- Follow logs: `make logs-<service>` or `cd <service> && docker compose logs -f`
- Restart a service: `make restart-<service>`
- Ports in use: override the default port via the corresponding env var (see port map above).
- ARM note: Mermaid image is pinned to `linux/arm64`; adjust `platform` if running on x86_64.

## Adding a new service
1. Create `<name>/compose.yml` — the Makefile auto-discovers it.
2. Optionally add `<name>/<name>-config/` for config files and `<name>/env.example` for secrets.
3. All ports should be configurable via `${ENV_VAR:-default}` in the compose file.
4. Update this README's service table and port map.
