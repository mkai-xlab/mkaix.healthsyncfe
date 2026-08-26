# Dockerized nginx deploy (local / Windows)

Runs the Flutter web build behind nginx inside Docker (`nginx:alpine`). The
image's default site is removed; only our `healthsync` site (in `conf.d/`)
is active.

Lives on the `devops/docker-nginx-deploy` branch — kept off `dev` on purpose.

## Files

| Path | Purpose |
| --- | --- |
| `docker/Dockerfile` | Multi-stage build: `flutter build web` → copy into an `nginx:alpine` image. |
| `docker/nginx/conf.d/healthsync.conf` | The nginx site config (SPA fallback to `index.html`, static asset caching, gzip). |
| `docker-compose.yml` | Builds and runs the image. Host port is `${HOST_PORT:-8080}`. |
| `.env.example` | Copy to `.env` to set `HOST_PORT` / `API_BASE_URL` without passing flags every time. |
| `scripts/deploy-windows.ps1` | One-shot script for Windows: `git checkout/pull` → `docker compose build` → `docker compose up -d`. |

## Quick test (port 8080, doesn't touch a host nginx on :80)

```bash
docker compose build
HOST_PORT=8080 docker compose up -d
curl -I http://localhost:8080
docker compose down
```

## Windows — real deploy (port 80)

```powershell
# From the repo root, in PowerShell:
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass   # once per session, if needed
.\scripts\deploy-windows.ps1
```

Defaults to `-Branch dev -Port 80 -ApiBaseUrl http://localhost:8000/api/v1`.
For a local smoke test instead: `.\scripts\deploy-windows.ps1 -Port 8080`.

Re-running the script is idempotent: it re-pulls `dev`, rebuilds the image,
and recreates the container.

## Notes

- `API_BASE_URL` is baked in at **build** time (`--dart-define`), matching
  `docs/environment.md`. Rebuild the image to change it.
- The container always serves on its internal port `80`; only the **host**
  side of the port mapping changes between the 8080 test and the 80 deploy.
- `docker compose down` stops and removes the container; the built image
  (`healthsync-fe-nginx:local`) stays cached for the next `up`.
