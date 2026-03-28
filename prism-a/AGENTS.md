# Prism A Service Notes

## OVERVIEW

Prism A is the baseline Prism stack. Its deploy-time env lives in `backend.env`, while the gateway, app containers, and internal Postgres are wired through the service-local compose and nginx config.

## WHERE TO LOOK

- `backend.env.example`, for the required runtime variables.
- `compose.yml`, for the Postgres, backend, frontend, gateway, healthchecks, and image tags.
- `nginx.conf`, for exact gateway routing.

## CONVENTIONS

- Copy `backend.env.example` to `backend.env` before deploy.
- Keep `PRISM_A_PORT`, `DATABASE_URL`, auth secrets, and CORS values aligned with your environment.
- Runtime env values are service-local, not shared from the repo root.
- Postgres stays internal-only with `expose: 5432`; only the nginx gateway publishes a host port.
- nginx sends `/api/`, `/v1/`, `/v1beta/`, `/docs`, `/redoc`, and `/openapi.json` to backend.
- nginx upgrades `/api/realtime/ws` as a websocket path and sends everything else to frontend.
- The gateway health endpoint is local to nginx at `/health`.

## ANTI-PATTERNS

- Don't edit the example file in place as the runtime file.
- Don't publish assumptions from Prism B here, because the two stacks are intentionally separate.
- Don't rename `backend.env`; the compose file expects that path.
- Don't publish Postgres from Prism A unless you also update the root port documentation and deployment assumptions.
