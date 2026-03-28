# Swiperflix Service Notes

## OVERVIEW

Swiperflix wraps its app with a pinned nginx proxy, a frontend, and a gateway that defaults to an OpenList backend on the host.

## WHERE TO LOOK

- `env.example`, for the OpenList connection and public port.
- `nginx.conf`, for the proxy behavior.
- `compose.yml`, for image versions, gateway env vars, healthchecks, and restart policy.

## CONVENTIONS

- Copy `env.example` to `.env` when you need local overrides.
- Keep the OpenList settings consistent with the backend you point it at.
- The proxy image is pinned, so app version changes should stay in the app image vars.
- The gateway defaults `OPENLIST_API_BASE_URL` to `http://host.docker.internal:5244` and stores SQLite data at `/data/swiperflix.db`.
- nginx sends `/api/` to the gateway, `/_next/static/` to frontend with long cache headers, and everything else to frontend.
- Only the reverse proxy publishes a host port; frontend and gateway stay internal.

## ANTI-PATTERNS

- Don't treat the proxy config as generic nginx boilerplate.
- Don't commit `.env`.
- Don't change the host port without updating the root port map.
- Don't forget the host-gateway dependency when pointing Swiperflix at a host-local OpenList instance.
