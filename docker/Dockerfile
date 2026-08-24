# syntax=docker/dockerfile:1

# ---------------------------------------------------------------------------
# Stage 1 — build the Flutter web bundle
# ---------------------------------------------------------------------------
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Fetch dependencies first so this layer is cached unless pubspec changes.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Now bring in the rest of the source and build.
COPY . .

# Backend base URL baked into the compiled web bundle at build time.
# Override with --build-arg API_BASE_URL=... (see docker-compose.yml).
ARG API_BASE_URL=http://localhost:8000/api/v1
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

# ---------------------------------------------------------------------------
# Stage 2 — serve the bundle with nginx (official alpine image: small and
# fast to pull). Config goes in conf.d/ — the "default" site that ships with
# the image is removed so only our "healthsync" site is active.
# ---------------------------------------------------------------------------
FROM nginx:alpine AS nginx

RUN rm -f /etc/nginx/conf.d/default.conf
COPY docker/nginx/conf.d/healthsync.conf /etc/nginx/conf.d/healthsync.conf

# Static site content (default nginx:alpine web root).
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
