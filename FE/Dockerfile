FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web --release --dart-define=API_BASE_URL=http://localhost:8080 && \
    printf "%s\n" \
      "self.addEventListener('install', event => self.skipWaiting());" \
      "self.addEventListener('activate', event => {" \
      "  event.waitUntil((async () => {" \
      "    const keys = await caches.keys();" \
      "    await Promise.all(keys.map(key => caches.delete(key)));" \
      "    await self.registration.unregister();" \
      "  })());" \
      "});" \
      > build/web/flutter_service_worker.js

FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80

