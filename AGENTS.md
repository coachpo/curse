# PROJECT KNOWLEDGE BASE

**Generated:** 2026-03-02
**Commit:** f3d3a97
**Branch:** main

## OVERVIEW

Docker Compose infrastructure monorepo for self-hosted services. No application source is maintained here; each top-level service directory provides a deployable stack via `compose.yml`. Primary deployment target is `capy.lan` (ARM/Linux).

## STRUCTURE

```
curse/
├── asspp/               # AssppWeb (IPA install/acquisition UI)
├── bark/                # Bark push gateway
├── clay-a/              # Clay OpenAI-compatible proxy (instance A)
├── clay-b/              # Clay OpenAI-compatible proxy (instance B)
├── herald/              # Herald (nginx + backend + frontend + worker)
├── mermaid/             # Mermaid Live Editor (ARM pinned)
├── portainer/           # Portainer CE
├── prism-a/             # Prism A (nginx + backend + frontend + postgres)
├── registry/            # Local Docker registry + custom config
├── swiperflix/          # Swiperflix (nginx + gateway + frontend)
├── whisper/             # Last Whisper (Caddy + backend + frontend)
├── Makefile             # Auto-discovers services and generates make targets
├── README.md            # Canonical service table + ports + runbook
└── AGENTS.md
```

Common service layout:

```
<service>/
├── compose.yml                  # Required (discovery boundary)
├── env.example                  # Optional template for .env
├── backend.env.example          # Optional template for backend.env
├── nginx.conf | Caddyfile       # Optional edge proxy config
└── <service>-config/            # Optional nested config directory
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add a new service | `<name>/compose.yml` | Must be top-level; Makefile scans only `*/compose.yml` |
| Start/stop services | `Makefile` | `start-<svc>`, `stop-<svc>`, `restart-<svc>`, `logs-<svc>` |
| Runtime port bindings | `make start-<svc>` output or `docker compose ... ps` | `make ports` is defaults table, not live bindings |
| Port defaults table | `README.md` + `Makefile:ports` | Keep both in sync when adding/changing ports |
| Reverse proxy routes | `herald/nginx.conf`, `prism-a/nginx.conf`, `swiperflix/nginx.conf`, `whisper/Caddyfile` | API/UI path behavior lives here |
| Clone Prism A data into Prism B | `prism-b/clone-prism-a-volume.sh` | Copies Prism A postgres volume into Prism B volume (target stack must be stopped) |
| Registry behavior | `registry/registry-config/config.yml` | Delete + CORS + upload purging |
| Herald runtime secrets | `herald/backend.env.example` -> `herald/backend.env` | Replace placeholders before deploy |
| Prism A runtime secrets | `prism-a/backend.env.example` -> `prism-a/backend.env` | File is named `backend.env.example` (not `env.example`) |
| Whisper credential path | `whisper/env.example` + `whisper/secrets/` | Secret file path defaults to `./secrets/google-credentials.json` |

## CODE MAP

| Symbol | Type | Location | Role |
|--------|------|----------|------|
| `SERVICES` | Make variable | `Makefile:8` | Service discovery from `*/compose.yml` |
| `compose` | Make macro | `Makefile:11` | Canonical compose invocation per service |
| `PRINT_RUNNING_PORTS` | Make macro | `Makefile:17` | Prints runtime published ports after start/restart |
| `SERVICE_TARGETS` | Make macro | `Makefile:54` | Generates per-service lifecycle/log targets |
| `start-all` / `stop-all` | Make targets | `Makefile:75`, `Makefile:77` | Bulk lifecycle over discovered services |
| `status` | Make target | `Makefile:79` | Shows per-service container state |
| `ports` | Make target | `Makefile:108` | Static defaults and env-var mapping table |

## CONVENTIONS

- Compose files are named `compose.yml` and live in top-level service directories.
- Host ports use `${SERVICE_PORT:-default}` interpolation in each service `ports` stanza.
- Environment variables are namespaced per service (`HERALD_*`, `PRISM_*`, `ASSPP_*`, etc.).
- `.env` and `backend.env` are gitignored; commit only template files (`env.example`, `backend.env.example`).
- Restart policy is `unless-stopped` except Portainer (`always`).
- Multi-container services expose internal ports and publish host ports only at the edge proxy.
- `make start-<service>` always runs `docker compose pull` before `up -d`.
- Healthchecks in compose files are runtime probes; there is no repo-level test framework/CI workflow.
- Explicit `name:` is used only for selected stacks (`herald`, `prism-a`, `prism-b`, `clay-a`, `clay-b`).

## ANTI-PATTERNS (THIS PROJECT)

- Never commit `.env`, `backend.env`, or real credential material.
- Never add services manually to `Makefile`; discovery is automatic from `*/compose.yml`.
- Never place new services under nested paths if you expect make auto-discovery.
- Never change default ports without updating both `README.md` and `Makefile:ports`.
- Never use non-namespaced env vars that can collide across services.
- Mermaid is pinned to `platform: linux/arm64`; do not remove without validating target architecture.
- Herald and Prism A/B use `backend.env` runtime files; do not rename templates to `env.example` without aligning compose `env_file`.

## UNIQUE STYLES

- Infra-only repo: orchestrates pre-built images; does not build application code locally.
- Service ownership boundary is the directory containing `compose.yml`; keep config artifacts co-located.
- Security posture differs by service: Herald applies `read_only`, `tmpfs`, and `no-new-privileges`; others are lighter.
- Proxy flavor varies by service (nginx vs Caddy); route semantics are service-specific.

## COMMANDS

```bash
# Preferred lifecycle interface
make services
make start-<service>
make stop-<service>
make restart-<service>
make logs-<service>
make start-all
make stop-all
make status
make ports
make prune-images
make clone-prism-b-from-prism-a

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
| 8089 | Clay A | `CLAY_A_PORT` |
| 8090 | Clay B | `CLAY_B_PORT` |
| 9000 | Portainer UI | `PORTAINER_PORT` |
| 9443 | Portainer HTTPS | `PORTAINER_HTTPS_PORT` |
