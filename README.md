# Curse Compose Stack

Self-hosted services packaged as separate Docker Compose bundles. All ports are configurable via environment variables. Services are auto-discovered by the Makefile.

## Prerequisites
- Docker + Docker Compose v2 on the host.
- (Herald) Copy `herald/backend.env.example` to `herald/backend.env` and fill in real values (`DJANGO_SECRET_KEY`, `JWT_SIGNING_KEY`, etc.).

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
| AssppWeb | iOS app acquisition and IPA install web UI | http://localhost:8086 | `asspp/env.example` (copy to `asspp/.env`, optional) |
| Mermaid Live Editor | Diagram editor | http://localhost:8083 | — |
| Registry | Local Docker registry | http://localhost:5000 | `registry/registry-config/config.yml`, volume `registry-data` |
| Herald | Herald (nginx → Django backend + worker + React frontend, SQLite) | http://localhost:8081 | `herald/backend.env` (copy from `herald/backend.env.example`), `herald/nginx.conf` |
| Prism A | Prism app (nginx gateway + backend + frontend) | http://localhost:8087 | `prism-a/backend.env` (copy from `prism-a/backend.env.example`), `prism-a/nginx.conf` |
| Prism B | Prism app clone for A/B testing (nginx gateway + backend + frontend) | http://localhost:8088 | `prism-b/backend.env` (copy from `prism-b/backend.env.example`), `prism-b/nginx.conf` |
| Clay A | Clay OpenAI-compatible proxy clone | http://localhost:8089 | `clay-a/env.example` (copy to `clay-a/.env`) |
| Clay B | Clay OpenAI-compatible proxy clone | http://localhost:8090 | `clay-b/env.example` (copy to `clay-b/.env`) |
| Clay C | Clay OpenAI-compatible proxy clone | http://localhost:8091 | `clay-c/env.example` (copy to `clay-c/.env`) |
| Swiperflix | Swiperflix (nginx proxy + gateway + frontend) | http://localhost:8084 | `swiperflix/env.example` (copy to `swiperflix/.env`), `swiperflix/nginx.conf` |
| Whisper | Last Whisper (Caddy proxy + backend + frontend) | http://localhost:8085 | `whisper/env.example` (copy to `whisper/.env`), `whisper/Caddyfile` |

## Default port map

All ports are overridable via environment variables in each service env file (`.env`/`backend.env`) or shell environment.

| Port | Service | Env var |
|------|---------|---------|
| 5000 | Docker Registry | `REGISTRY_PORT` |
| 8000 | Portainer edge | `PORTAINER_EDGE_PORT` |
| 8080 | Bark | `BARK_PORT` |
| 8081 | Herald (nginx proxy) | `HERALD_PORT` |
| 8083 | Mermaid | `MERMAID_PORT` |
| 8084 | Swiperflix proxy | `SWIPERFLIX_PORT` |
| 8085 | Whisper proxy | `WHISPER_PORT` |
| 8086 | AssppWeb | `ASSPP_PORT` |
| 8087 | Prism A gateway (nginx) | `PRISM_A_PORT` |
| 8088 | Prism B gateway (nginx) | `PRISM_B_PORT` |
| 8089 | Clay A | `CLAY_A_PORT` |
| 8090 | Clay B | `CLAY_B_PORT` |
| 8091 | Clay C | `CLAY_C_PORT` |
| 9000 | Portainer UI | `PORTAINER_PORT` |
| 9443 | Portainer HTTPS | `PORTAINER_HTTPS_PORT` |

## Configuration notes
- Config folders sit beside their Compose files, so relative paths in YAML stay valid.
- Registry: delete enabled via `REGISTRY_STORAGE_DELETE_ENABLED=true`; data persisted in `registry-data`.
- Prism A: gateway (nginx) listens on host port `PRISM_A_PORT` (default `8087`) and proxies internally to frontend/backend. Runtime settings/secrets live in `prism-a/backend.env`.
- Prism B: duplicated Prism stack for A/B tests. Gateway listens on `PRISM_B_PORT` (default `8088`) and uses isolated Postgres data plus `prism-b/backend.env`.
- Prism B includes `prism-b/clone-prism-a-volume.sh` to clone Prism A Postgres volume data into Prism B (stop Prism B first).
- Clay A / Clay B / Clay C: cloned Clay stacks with distinct Compose project names and ports (`CLAY_A_PORT` default `8089`, `CLAY_B_PORT` default `8090`, `CLAY_C_PORT` default `8091`) so they can run in parallel with independent `.env` configs.
- Herald: pulls pre-built GHCR images (`ghcr.io/coachpo/herald-backend:latest`, `ghcr.io/coachpo/herald-frontend:latest`) with `pull_policy: always`. nginx reverse-proxies to internal backend (:8100) and frontend (:3100). All runtime defaults are embedded in compose; only secrets (`DJANGO_SECRET_KEY`, etc.), `APP_BASE_URL`, and optional SMTP config go in `backend.env`.
- Swiperflix: pre-built GHCR images. Reverse proxy on `SWIPERFLIX_PORT` (default `8084`). All runtime defaults embedded in compose; only OpenList credentials need `.env`.
- Whisper: pre-built GHCR images. Caddy proxy on `WHISPER_PORT` (default `8085`). All runtime defaults embedded in compose; only `BACKEND_API_KEYS_CSV` and Google credentials JSON (`whisper/secrets/`) needed.
- AssppWeb: pre-built GHCR image (`ghcr.io/lakr233/assppweb:latest`). UI listens on `ASSPP_PORT` (default `8086`); optional behavior/security tuning is exposed in `asspp/env.example`.
- Volumes persist between restarts; remove with `docker volume rm <name>` if you want a clean slate.

## Troubleshooting
- Check status: `make status` or `docker compose -f <service>/compose.yml ps`
- Follow logs: `make logs-<service>` or `cd <service> && docker compose logs -f`
- Restart a service: `make restart-<service>`
- Clone Prism A data into Prism B: `make clone-prism-b-from-prism-a`
- Ports in use: override the default port via the corresponding env var (see port map above).
- ARM note: Mermaid image is pinned to `linux/arm64`; adjust `platform` if running on x86_64.

## Adding a new service
1. Create `<name>/compose.yml` — the Makefile auto-discovers it.
2. Optionally add `<name>/<name>-config/` for config files and `<name>/env.example` for secrets.
3. All ports should be configurable via `${ENV_VAR:-default}` in the compose file.
4. Update this README's service table and port map.
