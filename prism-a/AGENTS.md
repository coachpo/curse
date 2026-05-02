# Prism A Service Notes

## OVERVIEW

Prism A is the baseline Prism stack. Compose-time overrides live in `backend.env`, backend startup settings live in `prism-config/config.json`, and the gateway, app containers, and internal Postgres are wired through the service-local compose and nginx config.

## WHERE TO LOOK

- `backend.env.example`, for compose-time overrides such as the published gateway port.
- `config.json.example`, for the current Prism bootstrap contract that the backend reads at startup.
- `compose.yml`, for the Postgres, backend, frontend, gateway, healthchecks, and image tags.
- `nginx.conf`, for exact gateway routing.

## CONVENTIONS

- Copy `config.json.example` to `prism-config/config.json` before deploy.
- Copy `backend.env.example` to `backend.env` only when you need non-default compose-time overrides such as `PRISM_A_PORT`.
- Keep `PRISM_A_PORT` in `backend.env` when overriding it, and keep the bootstrap `database.url`, auth secrets, bundle key, and CORS values aligned in `prism-config/config.json`.
- The backend reads `PRISM_CONFIG_PATH=/etc/prism/config.json` from the compose file; the mounted directory provides the steady-state startup contract and lets Prism replace the file atomically.
- Old encrypted Prism bootstrap files are unsupported; replace them with the plaintext `config.json` layout before deploy.
- Postgres stays internal-only with `expose: 5432`; only the nginx gateway publishes a host port.
- nginx sends `/api/`, `/v1/`, `/v1beta/`, `/docs`, `/redoc`, and `/openapi.json` to backend.
- nginx upgrades `/api/realtime/ws` as a websocket path and sends everything else to frontend.
- The gateway health endpoint is local to nginx at `/health`.

## ANTI-PATTERNS

- Don't edit the example file in place as the runtime file.
- Don't publish assumptions from Prism B here, because the two stacks are intentionally separate.
- Don't rename `backend.env`; `deploy.sh` looks for that service-local env file when applying compose overrides.
- Don't publish Postgres from Prism A unless you also update the root port documentation and deployment assumptions.
