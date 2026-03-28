# Whisper Service Notes

## OVERVIEW

Whisper uses a Caddy edge, a backend, and a frontend, with one required local secrets path for Google TTS.

## WHERE TO LOOK

- `env.example`, for the port, API key, and credential file path.
- `Caddyfile`, for the proxy behavior.
- `compose.yml`, for the service wiring, secret mount, and pinned images.

## CONVENTIONS

- Copy `env.example` to `.env` before deploy.
- Put Google credentials at `./secrets/google-credentials.json`.
- Set `BACKEND_API_KEYS_CSV` to a real value before use.
- `GOOGLE_APPLICATION_CREDENTIALS_FILE` defaults to `./secrets/google-credentials.json` and is mounted as a Docker secret.
- Caddy sends `/apis/*`, `/v1/*`, `/api/v1/*`, `/metadata*`, and `/health` to backend, then sends everything else to frontend.
- Caddy also sets hardening headers and logs JSON to stdout.

## ANTI-PATTERNS

- Don't move the credential path unless the compose file changes too.
- Don't commit `.env` or the credentials JSON.
- Don't assume nginx routing here, because the edge proxy is Caddy.
- Don't drop the legacy `/apis/*` route unless you have checked frontend and client compatibility.
