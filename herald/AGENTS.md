# Herald Service Notes

## OVERVIEW

Herald is the stack with the tightest runtime rules. It uses pre-built GHCR images, a hardened nginx edge, and a `backend.env` runtime file that must be present before deploy.

## WHERE TO LOOK

- `backend.env.example`, for the required secrets and deployment values.
- `compose.yml`, for the backend, frontend, worker, SQLite volume, and security posture.
- `nginx.conf`, for exact request routing into backend and frontend.

## CONVENTIONS

- Copy `backend.env.example` to `backend.env` before starting the stack.
- Fill `DJANGO_SECRET_KEY`, `JWT_SIGNING_KEY`, `TOKEN_HASH_KEY`, and `CHANNEL_CONFIG_ENCRYPTION_KEY` with real values.
- Set `APP_BASE_URL` to the public URL for the stack.
- SMTP fields are optional and can stay blank if email is off.
- Backend and worker share the SQLite volume at `/data`, with `DATABASE_URL=sqlite:////data/db.sqlite3`.
- The worker runs `python manage.py deliveries_worker` from the backend image.
- nginx sends `/health`, `/api/`, and `/admin/` to backend, and everything else to frontend.
- The proxy keeps `client_max_body_size 2m` to stay just above the 1 MiB ingest limit.
- `reverse-proxy`, `frontend`, `backend`, and `worker` all use `restart: unless-stopped`.
- Herald is intentionally hardened with `read_only`, `tmpfs`, and `no-new-privileges` on the long-lived containers.

## ANTI-PATTERNS

- Don't rename `backend.env`; the compose file expects that path.
- Don't commit the runtime env file.
- Don't assume the proxy is generic, because Herald's route layout is service-specific.
- Don't treat Herald like the lighter stacks; its read-only/tmpfs security posture is deliberate.
