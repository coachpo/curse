# Curse Compose Stack

Self-hosted services packaged as separate Docker Compose bundles. All ports are configurable via environment variables. Services are auto-discovered by the Makefile.

## Prerequisites
- Docker + Docker Compose v2 on the host.
- (Spear) Copy `spear/env.example` to `spear/backend.env` and fill in real values (`DJANGO_SECRET_KEY`, `JWT_SIGNING_KEY`, etc.).

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
| Portainer | Docker management UI | http://localhost:9000, https://localhost:9443 (edge: 8000) | Volume `portainer_data` |
| Bark | iOS push gateway | http://localhost:8080 | — |
| Mermaid Live Editor | Diagram editor | http://localhost:8083 | — |
| Registry | Local Docker registry | http://localhost:5000 | `registry/registry-config/config.yml`, volume `registry-data` |
| Spear | Beacon Spear (nginx → Django backend + worker + React frontend, SQLite) | http://localhost:8081 | `spear/backend.env` (copy from `spear/env.example`), `spear/nginx.conf` |
| Prism | Prism app (nginx gateway + backend + frontend) | http://localhost:8082 | `prism/.env` (optional, copy from `prism/env.example`) |
| Swiperflix | Swiperflix (nginx proxy + gateway + frontend) | http://localhost:8084 | `swiperflix/env.example` (copy to `swiperflix/.env`), `swiperflix/nginx.conf` |
| Whisper | Last Whisper (Caddy proxy + backend + frontend) | http://localhost:8085 | `whisper/env.example` (copy to `whisper/.env`), `whisper/Caddyfile` |
| Telemetry | OTEL collector + Prometheus + Grafana | Grafana http://localhost:3000; Prometheus http://localhost:9090; OTLP gRPC :4317; OTLP HTTP :4318 | `telemetry/telemetry-config/*`, volumes `prometheus-data`, `grafana-data` |

## Default port map

All ports are overridable via environment variables in each service's `.env` file or shell environment.

| Port | Service | Env var |
|------|---------|---------|
| 3000 | Grafana | `GRAFANA_PORT` |
| 4317 | OTLP gRPC | `OTLP_GRPC_PORT` |
| 4318 | OTLP HTTP | `OTLP_HTTP_PORT` |
| 5000 | Docker Registry | `REGISTRY_PORT` |
| 8000 | Portainer edge | `PORTAINER_EDGE_PORT` |
| 8080 | Bark | `BARK_PORT` |
| 8081 | Spear (nginx proxy) | `SPEAR_PORT` |
| 8082 | Prism gateway (nginx) | `PRISM_HTTP_PORT` |
| 8083 | Mermaid | `MERMAID_PORT` |
| 8084 | Swiperflix proxy | `SWIPERFLIX_PORT` |
| 8085 | Whisper proxy | `WHISPER_PORT` |
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
- Registry: delete enabled via `REGISTRY_STORAGE_DELETE_ENABLED=true`; data persisted in `registry-data`.
- Prism: gateway (nginx) listens on host port `PRISM_HTTP_PORT` (default `8082`) and proxies internally to frontend/backend. Frontend API base is forced to same-origin by default; set `PRISM_FRONTEND_API_BASE` only if you need an explicit backend origin.
- Spear: pulls pre-built GHCR images (`ghcr.io/coachpo/beacon-spear-backend:latest`, `ghcr.io/coachpo/beacon-spear-frontend:latest`) with `pull_policy: always`. nginx reverse-proxies to internal backend (:8100) and frontend (:3100). All runtime defaults are embedded in compose; only secrets (`DJANGO_SECRET_KEY`, etc.), `APP_BASE_URL`, and optional SMTP config go in `backend.env`.
- Swiperflix: pre-built GHCR images. Reverse proxy on `SWIPERFLIX_PORT` (default `8084`). All runtime defaults embedded in compose; only OpenList credentials need `.env`.
- Whisper: pre-built GHCR images. Caddy proxy on `WHISPER_PORT` (default `8085`). All runtime defaults embedded in compose; only `BACKEND_API_KEYS_CSV` and Google credentials JSON (`whisper/secrets/`) needed.
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
