# PROJECT KNOWLEDGE BASE

**Generated:** 2026-02-22
**Commit:** 800c33a
**Branch:** main

## OVERVIEW

Docker Compose stack repo — collection of independently deployable self-hosted services. No application code; purely infrastructure configs (YAML). Target host: `capy.lan` (ARM/linux). Services auto-discovered by Makefile via `*/compose.yml` glob.

## STRUCTURE

```
curse/
├── bark/                # iOS push gateway (Bark)
├── mermaid/             # Mermaid Live Editor (diagram tool)
├── portainer/           # Docker management UI
├── prism/               # Prism app (backend + frontend, pre-built images)
├── registry/            # Local Docker registry with delete + CORS enabled
├── spear/               # Beacon Spear (nginx → Django backend + worker + React frontend, SQLite)
├── swiperflix/          # Swiperflix (nginx proxy + gateway + frontend, pre-built images)
├── telemetry/           # OTEL Collector → Prometheus → Grafana pipeline
├── whisper/             # Last Whisper (Caddy proxy + backend + frontend, pre-built images)
├── Makefile             # Auto-discovers services, provides start/stop/restart/logs/status
└── README.md
```

Each service follows the same pattern:
```
<service>/
├── compose.yml                  # Docker Compose definition
├── <service>-config/            # optional config subfolder
└── env.example                  # optional, copy to .env
```

Spear layout (pulls pre-built images from GHCR, no config subfolder):
```
spear/
├── compose.yml          # nginx proxy + backend + frontend + worker
├── nginx.conf           # Reverse proxy config (API → backend, SPA → frontend)
└── env.example          # Template — copy to backend.env
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add a new service | Create `<name>/compose.yml` | Auto-discovered by Makefile — no edits needed |
| Change ports | `compose.yml` in each service dir | All ports use `${ENV_VAR:-default}` pattern |
| Telemetry tuning | `telemetry/telemetry-config/` | OTEL, Prometheus, Grafana configs |
| Registry settings | `registry/registry-config/config.yml` | Delete, CORS, purging, proxy cache |
| Spear routing | `spear/nginx.conf` | nginx reverse proxy rules (API → backend, SPA → frontend) |
| Orchestration | `Makefile` (root) | `make start-<svc>`, `make stop-<svc>`, `make status`, `make ports` |

## CONVENTIONS

- Compose files are named `compose.yml` (modern Docker Compose v2 convention).
- `.env` and `backend.env` files are gitignored. Always provide `env.example` as template.
- Config folders sit beside their compose files so relative paths in YAML stay valid.
- All services use `restart: unless-stopped` (portainer uses `always`).
- Networks are defined per service; many use `<service>-network`, telemetry uses `curse-telemetry`, spear uses `beacon`, and prism uses the default project network.
- All host ports are configurable via `${ENV_VAR:-default}` in compose files.
- Env var names are namespaced per service (e.g. `PRISM_HTTP_PORT`, `SPEAR_PORT`) to avoid collisions.
- Use explicit `container_name` only where it adds operational clarity.
- No start scripts — use `make start-<service>` or `cd <service> && docker compose up -d`.

## ANTI-PATTERNS (THIS PROJECT)

- **Never commit `.env` or `backend.env` files** — secrets only via gitignored files, templates in `env.example`.
- **Never change ports without checking the full port table** in README.
- **Never use generic env var names** — always namespace with service prefix (e.g. `PRISM_*`, `SPEAR_*`).
- **Mermaid is ARM-only** — `platform: linux/arm64` hardcoded. Change if deploying to x86_64.
- **Spear placeholder secrets** — `DJANGO_SECRET_KEY`, `JWT_SIGNING_KEY`, `TOKEN_HASH_KEY`, `CHANNEL_CONFIG_ENCRYPTION_KEY` in `spear/env.example` must be replaced. All runtime defaults are embedded in compose.yml.
- **Spear does not build images locally** — it must pull `ghcr.io/coachpo/beacon-spear-backend:latest` and `ghcr.io/coachpo/beacon-spear-frontend:latest` from GHCR.
- **Don't add services to Makefile manually** — it auto-discovers `*/compose.yml`.

## COMMANDS

```bash
# Preferred: use Makefile
make start-<service>       # start one
make stop-<service>        # stop one
make restart-<service>     # restart one
make logs-<service>        # tail logs
make start-all             # start everything
make stop-all              # stop everything
make status                # show all containers
make ports                 # show port assignments
make services              # list discovered services

# Or compose directly
cd <service> && docker compose up -d
cd <service> && docker compose down
cd <service> && docker compose logs -f
```

## PORT MAP

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
