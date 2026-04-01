# Curse Compose Stack

Self-hosted services packaged as separate Docker Compose bundles. `./deploy.sh` is the canonical deployment interface, and ports stay configurable through service env files.

## Quick start

```bash
./deploy.sh
./deploy.sh services
./deploy.sh ports
./deploy.sh status
./deploy.sh start <service>
./deploy.sh <service> start
./deploy.sh start <service> --version 1.2.3
./deploy.sh restart <service> --version 1.2.3
./deploy.sh force <service> --version 1.2.3
./deploy.sh stop <service>
./deploy.sh logs <service>
./deploy.sh start-all --version 1.2.3
./deploy.sh stop-all
./deploy.sh prune-images
./deploy.sh clone-prism-b-from-prism-a
```

`deploy.sh` auto-discovers repo folders containing `compose.yml`, `compose.yaml`, `docker-compose.yml`, or `docker-compose.yaml`, and skips `.git` and `.sisyphus`. `start` always runs `docker compose pull` before `up -d`.

The service-first shorthand also works for `stop`, `restart`, `force`, and `logs`.

App images use path-derived version vars such as `HERALD_VERSION`, `PRISM_A_VERSION`, `PRISM_B_VERSION`, and `CLI_PROXY_API_VERSION`. Nested service paths are uppercased with non-alphanumeric characters converted to `_`, then suffixed with `_VERSION`. Each app image defaults to `latest`; pinned dependencies stay pinned.

## Using Compose directly

```bash
docker compose -f <service>/compose.yml up -d
docker compose -f <service>/compose.yml down
docker compose -f <service>/compose.yml logs -f
```

## Services at a glance
| Service | Purpose | Default URL/Port | Config |
| --- | --- | --- | --- |
| Portainer | Docker management UI | http://localhost:9000, https://localhost:9443 (edge: 8000) | Volume `portainer_data` |
| Bark | iOS push gateway | http://localhost:8080 | — |
| AssppWeb | iOS app acquisition and IPA install web UI | http://localhost:8086 | `asspp/env.example` |
| Mermaid Live Editor | Diagram editor | http://localhost:8083 | — |
| Registry | Local Docker registry | http://localhost:5000 | `registry/registry-config/config.yml`, volume `registry-data` |
| Herald | Herald stack | http://localhost:8081 | `herald/backend.env`, `herald/nginx.conf` |
| Prism A | Prism stack | http://localhost:8087 | `prism-a/backend.env`, `prism-a/nginx.conf` |
| Prism B | Prism clone for A/B testing | http://localhost:8088, PostgreSQL: localhost:8432 | `prism-b/backend.env`, `prism-b/nginx.conf` |
| Clay | Clay OpenAI-compatible proxy | http://localhost:8089 | `clay/env.example` |
| CLIProxyAPI | Multi-provider CLI/API proxy | http://localhost:8317 | `cli-proxy-api/env.example`, `cli-proxy-api/config.yaml` |
| Swiperflix | Swiperflix stack | http://localhost:8084 | `swiperflix/env.example`, `swiperflix/nginx.conf` |
| Whisper | Last Whisper stack | http://localhost:8085 | `whisper/env.example`, `whisper/Caddyfile` |
| n8n | Workflow automation platform | http://localhost:8091 | Volume `n8n_data` |

## Default port map

All ports are overridable via service env files or shell environment.

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
- `tests/test_deploy.sh` checks the deploy surface, version-variable convention, and discovery rules.
- `deploy.sh ports` prints the defaults table, not live bindings.
- Portainer is the only service with `restart: always`; the others use `restart: unless-stopped`.
- Prism B intentionally publishes PostgreSQL on `PRISM_B_POSTGRES_PORT` and keeps its own data volume.
- Prism B ships `prism-b/clone-prism-a-volume.sh` for copying Prism A Postgres data into Prism B, and Prism B must be stopped first.
- Mermaid is pinned to `platform: linux/arm64`.
- Registry delete is enabled in `registry/registry-config/config.yml`.
- `cli-proxy-api/config.yaml` includes a placeholder API key that must be replaced before use.

## Setup gotchas by service

- Herald, copy `herald/backend.env.example` to `herald/backend.env` and fill the secret keys plus `APP_BASE_URL`. SMTP is optional.
- Prism A, copy `prism-a/backend.env.example` to `prism-a/backend.env`. It needs a matching `DATABASE_URL`, auth secrets, and CORS values.
- Prism B, copy `prism-b/backend.env.example` to `prism-b/backend.env`. It uses the same runtime knobs as Prism A, plus the exposed Postgres port.
- Whisper, copy `whisper/env.example` to `whisper/.env`, set `BACKEND_API_KEYS_CSV`, and provide `whisper/secrets/google-credentials.json`.
- Clay, copy `clay/env.example` to `clay/.env` and set `OPENAI_API_KEY`.
- CLIProxyAPI, copy `cli-proxy-api/env.example` if needed, then edit `cli-proxy-api/config.yaml` and replace the placeholder API key.
- AssppWeb, copy `asspp/env.example` to `asspp/.env` only if you need the optional settings there.

## Troubleshooting
- Check status: `./deploy.sh status` or `docker compose -f <service>/compose.yml ps`
- Follow logs: `./deploy.sh logs <service>`
- Restart a service: `./deploy.sh restart <service> [--version TAG]`
- Force redeploy a service and wipe its Compose-managed volumes: `./deploy.sh force <service> [--version TAG]`
- Clone Prism A data into Prism B: `./deploy.sh clone-prism-b-from-prism-a`
- Remove unused untagged images for discovered repositories: `./deploy.sh prune-images`

## Adding a new service
1. Create a folder anywhere in the repo with `compose.yml` or another supported compose filename.
2. Keep service-local config beside the compose file.
3. Make host ports configurable with `${ENV_VAR:-default}` in the compose file.
4. Use the path-derived `${SERVICE_PATH_VERSION:-latest}` convention for app images.
5. Update the root README port map and service table when defaults change.
