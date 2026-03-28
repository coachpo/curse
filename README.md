# Curse Compose Stack

Self-hosted services packaged as separate Docker Compose bundles. All ports are configurable via environment variables, and `./deploy.sh` is the canonical deployment manager.

## Prerequisites
- Docker + Docker Compose v2 on the host.
- (Herald) Copy `herald/backend.env.example` to `herald/backend.env` and fill in real values (`DJANGO_SECRET_KEY`, `JWT_SIGNING_KEY`, etc.).

## How to run

### Using `deploy.sh` (recommended)
```bash
./deploy.sh                         # Interactive: choose service, action, and optional version tag
./deploy.sh services                # List discovered services
./deploy.sh ports                   # Show default port assignments
./deploy.sh status                  # Show running containers
./deploy.sh start bark              # Start a single service with latest app images
./deploy.sh start bark --version 1.2.3
./deploy.sh restart prism-a --version 2026.03.28
./deploy.sh stop bark
./deploy.sh logs bark
./deploy.sh start-all --version 2026.03.28
./deploy.sh stop-all
./deploy.sh prune-images
./deploy.sh clone-prism-b-from-prism-a
```

`deploy.sh` auto-discovers repo folders containing `compose.yml`, `compose.yaml`, `docker-compose.yml`, or `docker-compose.yaml`.

### Using Compose directly
Each service keeps its own compose file in its directory:
```bash
docker compose -f <service>/compose.yml up -d
docker compose -f <service>/compose.yml down
docker compose -f <service>/compose.yml logs -f
```

App images are versioned through per-service env vars such as `HERALD_VERSION`, `PRISM_A_VERSION`, and `CLI_PROXY_API_VERSION`. For nested service folders, the variable name is derived from the repo-relative path with non-alphanumeric characters converted to underscores. Every app image defaults to `latest` when no version is supplied; pinned dependency images inside mixed stacks stay pinned.

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
| Prism B | Prism app clone for A/B testing (nginx gateway + backend + frontend) | http://localhost:8088, PostgreSQL: localhost:8432 | `prism-b/backend.env` (copy from `prism-b/backend.env.example`), `prism-b/nginx.conf` |
| Clay | Clay OpenAI-compatible proxy | http://localhost:8089 | `clay/env.example` (copy to `clay/.env`) |
| CLIProxyAPI | Multi-provider CLI/API proxy with repo-local auth state | http://localhost:8317 | `cli-proxy-api/env.example` (copy to `cli-proxy-api/.env`, optional), edit `cli-proxy-api/config.yaml`, repo-local state under `cli-proxy-api/state/auth/` |
| Swiperflix | Swiperflix (nginx proxy + gateway + frontend) | http://localhost:8084 | `swiperflix/env.example` (copy to `swiperflix/.env`), `swiperflix/nginx.conf` |
| Whisper | Last Whisper (Caddy proxy + backend + frontend) | http://localhost:8085 | `whisper/env.example` (copy to `whisper/.env`), `whisper/Caddyfile` |
| n8n | Workflow automation platform | http://localhost:8091 | Volume `n8n_data` |

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
| 8432 | Prism B PostgreSQL | `PRISM_B_POSTGRES_PORT` |
| 8089 | Clay | `CLAY_PORT` |
| 8091 | n8n | `N8N_PORT` |
| 8317 | CLIProxyAPI | `CLI_PROXY_API_PORT` |
| 9000 | Portainer UI | `PORTAINER_PORT` |
| 9443 | Portainer HTTPS | `PORTAINER_HTTPS_PORT` |

## Configuration notes
- Config folders sit beside their compose files, so relative paths in YAML stay valid.
- Registry: delete enabled via `REGISTRY_STORAGE_DELETE_ENABLED=true`; data persisted in `registry-data`.
- Prism A: gateway (nginx) listens on host port `PRISM_A_PORT` (default `8087`) and proxies internally to frontend/backend. Runtime settings/secrets live in `prism-a/backend.env`.
- Prism B: duplicated Prism stack for A/B tests. Gateway listens on `PRISM_B_PORT` (default `8088`), PostgreSQL is also published on `PRISM_B_POSTGRES_PORT` (default `8432`), and the stack uses isolated Postgres data plus `prism-b/backend.env`.
- Prism B includes `prism-b/clone-prism-a-volume.sh` to clone Prism A Postgres volume data into Prism B (stop Prism B first).
- Clay: single Clay stack exposed on `CLAY_PORT` (default `8089`) with repo-local config in `clay/.env`.
- CLIProxyAPI: pre-built Docker Hub image. The primary API listens on `CLI_PROXY_API_PORT` (default `8317`). The tracked `cli-proxy-api/config.yaml` mounts to `/CLIProxyAPI/config.yaml`, and repo-local auth/session state persists under `cli-proxy-api/state/auth/`. Replace the placeholder API key in `cli-proxy-api/config.yaml` before starting.
- Herald: uses pre-built GHCR images. `deploy.sh` pulls before `up -d`, nginx reverse-proxies to internal backend (:8100) and frontend (:3100), and runtime secrets, `APP_BASE_URL`, and optional SMTP config live in `herald/backend.env`.
- Swiperflix: pre-built GHCR app images behind a pinned nginx reverse proxy on `SWIPERFLIX_PORT` (default `8084`).
- Whisper: pre-built GHCR app images behind a pinned Caddy proxy on `WHISPER_PORT` (default `8085`). Only `BACKEND_API_KEYS_CSV` and Google credentials JSON (`whisper/secrets/`) are required.
- AssppWeb: pre-built GHCR image. UI listens on `ASSPP_PORT` (default `8086`); optional behavior/security tuning is exposed in `asspp/env.example`.
- Volumes persist between restarts; remove with `docker volume rm <name>` if you want a clean slate.

## Troubleshooting
- Check status: `./deploy.sh status` or `docker compose -f <service>/compose.yml ps`
- Follow logs: `./deploy.sh logs <service>`
- Restart a service: `./deploy.sh restart <service> [--version TAG]`
- Clone Prism A data into Prism B: `./deploy.sh clone-prism-b-from-prism-a`
- Remove unused untagged images for discovered repositories: `./deploy.sh prune-images`
- Ports in use: override the default port via the corresponding env var (see port map above).
- ARM note: Mermaid is pinned to `linux/arm64`; adjust `platform` if running on x86_64.

## Adding a new service
1. Create a folder anywhere in the repo with `compose.yml` (or another supported compose filename).
2. Optionally add `<name>/<name>-config/` for config files and `<name>/env.example` for secrets.
3. All ports should be configurable via `${ENV_VAR:-default}` in the compose file.
4. App images should use the path-derived version convention `${SERVICE_PATH_VERSION:-latest}` with non-alphanumeric characters converted to underscores.
5. Update this README's service table and port map.
