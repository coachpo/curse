# PROJECT KNOWLEDGE BASE

**Generated:** 2026-03-28
**Branch:** main

## OVERVIEW

Docker Compose infrastructure monorepo for self-hosted services. Each service directory owns its own deployable stack, config examples, and service-specific docs. Primary deployment target is `capy.lan` on ARM/Linux. The canonical deployment interface is the repo-root `deploy.sh` script.

## STRUCTURE

```text
curse/
├── asspp/               # AssppWeb (IPA install/acquisition UI)
├── bark/                # Bark push gateway
├── clay/                # Clay OpenAI-compatible proxy
├── cli-proxy-api/       # CLIProxyAPI
├── herald/              # Herald (nginx + backend + frontend + worker)
├── mermaid/             # Mermaid Live Editor (ARM pinned)
├── n8n/                 # n8n workflow automation
├── portainer/           # Portainer CE
├── prism-a/             # Prism A (nginx + backend + frontend + postgres)
├── prism-b/             # Prism B clone stack for A/B testing
├── registry/            # Local Docker registry + custom config
├── swiperflix/          # Swiperflix (nginx + gateway + frontend)
├── whisper/             # Last Whisper (Caddy + backend + frontend)
├── deploy.sh            # Canonical deployment manager
├── README.md            # Canonical service table + ports + runbook
├── tests/               # Shell checks for deploy surface and repo conventions
└── AGENTS.md
```

Common service layout:

```text
<service>/
├── compose.yml | compose.yaml | docker-compose.yml | docker-compose.yaml
├── AGENTS.md                      # Optional service-local notes for complex stacks
├── env.example                  # Optional template for .env
├── backend.env.example          # Optional template for backend.env
├── nginx.conf | Caddyfile       # Optional edge proxy config
└── <service>-config/            # Optional nested config directory
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add a service | `<path>/<compose-file>` | Discovery is automatic from supported compose filenames |
| Start/stop/restart/log services | `deploy.sh` | Supports `./deploy.sh start <service>` and `./deploy.sh <service> start` |
| Runtime port bindings | `docker compose ... ps` after a start | `./deploy.sh ports` is the defaults table only |
| Port defaults table | `README.md` + `deploy.sh ports` | Keep both in sync when changing ports |
| Reverse proxy routes | `herald/nginx.conf`, `prism-a/nginx.conf`, `prism-b/nginx.conf`, `swiperflix/nginx.conf`, `whisper/Caddyfile` | API/UI path behavior lives here |
| Clone Prism A data into Prism B | `prism-b/clone-prism-a-volume.sh` | Prism B must be stopped first |
| Registry behavior | `registry/registry-config/config.yml` | Delete + CORS + upload purging |
| Service test coverage | `tests/test_deploy.sh` | Encodes deploy-script and docs expectations |
| Herald runtime secrets | `herald/backend.env.example` -> `herald/backend.env` | Replace placeholders before deploy |
| Prism A runtime secrets | `prism-a/backend.env.example` -> `prism-a/backend.env` | File is named `backend.env.example` |
| Prism B runtime secrets | `prism-b/backend.env.example` -> `prism-b/backend.env` | Same convention as Prism A |
| Clay runtime env | `clay/env.example` -> `clay/.env` | `OPENAI_API_KEY` is required before start |
| CLIProxyAPI tracked config | `cli-proxy-api/config.yaml`, `cli-proxy-api/state/auth/` | Replace placeholder API key; auth state stays repo-local |
| Asspp optional tuning | `asspp/env.example` -> `asspp/.env` | Public base URL, cleanup, and access password are optional |
| Whisper credential path | `whisper/env.example` + `whisper/secrets/` | Secret file path defaults to `./secrets/google-credentials.json` |

## CODE MAP

| Symbol / Surface | Type | Location | Role |
|------------------|------|----------|------|
| `discover_services` | Bash function | `deploy.sh` | Finds repo service folders by supported compose filenames |
| `run_compose_with_version` | Bash function | `deploy.sh` | Sets per-service version env vars before compose commands |
| `print_running_ports` | Bash function | `deploy.sh` | Prints published host ports after start/restart |
| `prune_images` | Bash function | `deploy.sh` | Removes unused untagged images for repos referenced by discovered services |
| `clone_prism_b_from_prism_a` | Bash function | `deploy.sh` | Dispatches to `./prism-b/clone-prism-a-volume.sh` |
| `${SERVICE_NAME_VERSION:-latest}` | Compose convention | service compose files | App image tag override per service directory |

## CONVENTIONS

- Services are discovered from repo subdirectories containing one of: `compose.yml`, `compose.yaml`, `docker-compose.yml`, `docker-compose.yaml`.
- `.git` and `.sisyphus` are skipped by discovery.
- Host ports use `${SERVICE_PORT:-default}` interpolation in each service `ports` stanza.
- App images use per-service version variables derived from the repo-relative service path, uppercased with non-alphanumeric characters converted to `_`, then suffixed with `_VERSION`.
- App images default to `latest` when no version is supplied.
- Mixed stacks version only their app images; pinned dependencies like `nginx`, `postgres`, and `caddy` stay pinned.
- `.env` and `backend.env` are gitignored; commit only template files (`env.example`, `backend.env.example`).
- Restart policy is `unless-stopped` except Portainer (`always`).
- Multi-container services expose internal ports and publish host ports only at the edge proxy, except Prism B Postgres which is intentionally published.
- `deploy.sh start <service>` always runs `docker compose pull` before `up -d`.
- Healthchecks in compose files are runtime probes; shell smoke tests live under `tests/`.
- Explicit `name:` is used only for selected stacks (`herald`, `prism-a`, `prism-b`, `clay`).
- Mermaid is pinned to `platform: linux/arm64`.
- Complex multi-container stacks can carry a service-local `AGENTS.md` when parent-level rules are not specific enough.

## ANTI-PATTERNS (THIS PROJECT)

- Never commit `.env`, `backend.env`, or real credential material.
- Never hardcode service lists in `deploy.sh`; discovery must stay automatic.
- Never change default ports without updating both `README.md` and `deploy.sh ports`.
- Never use non-namespaced env vars that can collide across services.
- Herald and Prism A/B use `backend.env` runtime files; do not rename templates without aligning compose `env_file`.
- Never retag mixed-stack dependency images just to make version rollout easier; only app images should follow the per-service version variable pattern.
- Prism B clone script requires Prism B to be stopped first.

## UNIQUE STYLES

- Infra-only repo: orchestrates pre-built images; does not build application code locally.
- Service ownership boundary is the directory containing the compose file; keep config artifacts co-located.
- Security posture differs by service: Herald applies `read_only`, `tmpfs`, and `no-new-privileges`; others are lighter.
- Proxy flavor varies by service (nginx vs Caddy); route semantics are service-specific.
- `deploy.sh` provides both interactive UX for manual operation and deterministic CLI commands for automation.
- `deploy.sh` is exercised by `tests/test_deploy.sh`, so docs should stay in step with that contract.

## COMMANDS

```bash
# Preferred lifecycle interface
./deploy.sh
./deploy.sh services
./deploy.sh <service> start
./deploy.sh start <service> [--version TAG]
./deploy.sh stop <service>
./deploy.sh restart <service> [--version TAG]
./deploy.sh logs <service>
./deploy.sh start-all [--version TAG]
./deploy.sh stop-all
./deploy.sh status
./deploy.sh ports
./deploy.sh prune-images
./deploy.sh clone-prism-b-from-prism-a

# Direct compose (one service)
docker compose -f <service>/compose.yml up -d
docker compose -f <service>/compose.yml down
docker compose -f <service>/compose.yml logs -f
```

## PORT MAP

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
