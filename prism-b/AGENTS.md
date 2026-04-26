# Prism B Service Notes

## OVERVIEW

Prism B mirrors Prism A for A/B work. Compose-time overrides live in `backend.env`, backend startup settings live in `config.json`, and Prism B keeps its own published Postgres port and clone helper.

## WHERE TO LOOK

- `backend.env.example`, for Prism B compose-time overrides.
- `config.json.example`, for the current Prism bootstrap contract that the backend reads at startup.
- `compose.yml`, for the separate Postgres, gateway, and app services.
- `nginx.conf`, for exact gateway routing.
- `clone-prism-a-volume.sh`, for copying Prism A data into Prism B.

## CONVENTIONS

- Copy `backend.env.example` to `backend.env` and `config.json.example` to `config.json` before deploy.
- Keep `PRISM_B_PORT` and `PRISM_B_POSTGRES_PORT` aligned with the exposed ports you want.
- Keep the bootstrap `database.url`, auth secrets, bundle key, and CORS values aligned in `config.json`.
- The backend reads `PRISM_CONFIG_PATH=/etc/prism/config.json` from the compose file; the JSON file is the steady-state startup contract.
- Stop Prism B before running the clone script.
- Postgres is intentionally host-published on `PRISM_B_POSTGRES_PORT` instead of staying internal-only.
- nginx routes `/api/`, `/v1/`, `/v1beta/`, `/docs`, `/redoc`, and `/openapi.json` to backend.
- nginx upgrades `/api/realtime/ws` as a websocket path and sends the rest to frontend.
- The clone helper resolves compose-managed volume names, creates the target volume if needed, clears the target, and copies Prism A data in.

## ANTI-PATTERNS

- Don't run the clone helper against a live Prism B stack.
- Don't commit the runtime env file.
- Don't commit `config.json`; keep the tracked example file as the template.
- Don't reuse Prism A data paths without checking the isolated volume layout.
- Don't assume Prism A and Prism B share the same exposure model; Prism B is the one with the published database port.
