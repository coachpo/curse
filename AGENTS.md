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
├── duck-free/           # DuckCoding availability notifier → depends on Bark
├── mermaid/             # Mermaid Live Editor (diagram tool)
├── portainer/           # Docker management UI
├── prism/               # Prism app (backend + frontend, pre-built images)
├── registry/            # Local Docker registry with delete + CORS enabled
├── spear/               # Beacon Spear (Caddy → Django backend + worker + React frontend, SQLite)
├── telemetry/           # OTEL Collector → Prometheus → Grafana pipeline
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

Spear layout (non-standard — no config subfolder, extra files):
```
spear/
├── compose.yml          # Caddy + backend + frontend
├── Caddyfile            # Reverse proxy config (TLS, routing)
├── entrypoint.sh        # Backend entrypoint (migrations + worker + gunicorn)
└── env.example          # Required — copy to .env
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add a new service | Create `<name>/compose.yml` | Auto-discovered by Makefile — no edits needed |
| Change ports | `compose.yml` in each service dir | All ports use `${ENV_VAR:-default}` pattern |
| Telemetry tuning | `telemetry/telemetry-config/` | OTEL, Prometheus, Grafana configs |
| Registry settings | `registry/registry-config/config.yml` | Delete, CORS, purging, proxy cache |
| Service secrets | `<service>/env.example` → `<service>/.env` | duck-free uses `duck-free-config/.env.duck-free` |
| Spear routing | `spear/Caddyfile` | Caddy reverse proxy rules (API → backend, SPA → frontend) |
| Spear backend startup | `spear/entrypoint.sh` | Migrations, delivery worker, gunicorn |
| Orchestration | `Makefile` (root) | `make start-<svc>`, `make stop-<svc>`, `make status`, `make ports` |

## CONVENTIONS

- Compose files are named `compose.yml` (modern Docker Compose v2 convention).
- `.env` files are gitignored. Always provide `env.example` as template.
- Config folders sit beside their compose files so relative paths in YAML stay valid.
- All services use `restart: unless-stopped` (portainer uses `always`).
- Each service gets its own Docker bridge network (named `<service>-network`).
- Telemetry network is `curse-telemetry`.
- Spear uses `public` + `internal` networks (frontend has no direct internet egress).
- All host ports are configurable via `${ENV_VAR:-default}` in compose files.
- Env var names are namespaced per service (e.g. `PRISM_BACKEND_PORT`, `SPEAR_HTTP_PORT`) to avoid collisions.
- All services set explicit `container_name` for consistent `docker ps` output.
- No start scripts — use `make start-<service>` or `cd <service> && docker compose up -d`.

## ANTI-PATTERNS (THIS PROJECT)

- **Never commit `.env` files** — secrets only via gitignored `.env`, templates in `env.example`.
- **Never change ports without checking the full port table** in README.
- **Never use generic env var names** — always namespace with service prefix (e.g. `PRISM_*`, `SPEAR_*`).
- **Mermaid is ARM-only** — `platform: linux/arm64` hardcoded. Change if deploying to x86_64.
- **Spear `change-me` placeholders** — `DJANGO_SECRET_KEY`, `JWT_SIGNING_KEY`, `TOKEN_HASH_KEY` in `spear/env.example` must be replaced.
- **Spear requires `GHCR_OWNER`** — image refs use `ghcr.io/${GHCR_OWNER}/beacon-spear-*`. Set in `.env`.
- **Duck Free requires `.env.duck-free`** — hard exit if missing. Copy from `example.env` first.
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
