Spear deployment bundle.

Files:
- `docker-compose.spear.yml`: compose that runs prebuilt images.
- `.env.example`: configuration template for compose interpolation + runtime env.

Typical usage:
- Copy `spear/.env.example` to `spear/.env` and fill values.
- Start:
  - `./spear/start_spear.sh`
- Or from repo root:
  - `docker compose --project-directory spear --env-file spear/.env -f spear/docker-compose.spear.yml up -d`

Default ports:
- Frontend: http://localhost:13000
- Backend: http://localhost:18000
