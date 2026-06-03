# Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

ARG ENVIRONMENT=production
ARG API_BASE_URL=http://localhost:3000
ARG TECAAI_BASE_URL=http://localhost:5001
ARG UPLOADS_BASE_URL=http://localhost:3000
ARG API_REQUEST_TIMEOUT=30
ARG TECAAI_REQUEST_TIMEOUT=30
ARG MAX_FILE_SIZE=10485760
ARG ENABLE_HTTPS=false
ARG DEBUG_MODE=false
ARG LOG_LEVEL=error
ARG CONFIG_HASH=default

# Invalida cache do Docker quando CONFIG_HASH / URLs mudam no .env
RUN echo "CONFIG_HASH=${CONFIG_HASH}"

RUN printf '%s\n' \
  "ENVIRONMENT=${ENVIRONMENT}" \
  "API_BASE_URL=${API_BASE_URL}" \
  "TECAAI_BASE_URL=${TECAAI_BASE_URL}" \
  "UPLOADS_BASE_URL=${UPLOADS_BASE_URL}" \
  "API_REQUEST_TIMEOUT=${API_REQUEST_TIMEOUT}" \
  "TECAAI_REQUEST_TIMEOUT=${TECAAI_REQUEST_TIMEOUT}" \
  "MAX_FILE_SIZE=${MAX_FILE_SIZE}" \
  "ENABLE_HTTPS=${ENABLE_HTTPS}" \
  "ENABLE_CORS=true" \
  "DEBUG_MODE=${DEBUG_MODE}" \
  "LOG_LEVEL=${LOG_LEVEL}" \
  "ENABLE_ANALYTICS=false" \
  "ENABLE_CRASH_REPORTING=false" \
  > .env

RUN flutter build web --release

FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
