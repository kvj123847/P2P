# Final Render Deployment Guide

## Repository layout

- Core API: `backend/core-api`
- Session Engine: `backend/session-engine`
- Flutter client: `mobile`
- Render Blueprint: `render.yaml`

## Render services

### Core API

- Name: `peer-learning-core-api`
- Runtime: Docker
- Dockerfile: `backend/core-api/Dockerfile`
- Docker context: `backend/core-api`
- Health check: `/health`
- Readiness check: `/readyz`

The Docker image uses Node 20 and Debian Bookworm with OpenSSL so Prisma
5 can select compatible native libraries.

### Session Engine

- Name: `peer-learning-session-engine`
- Runtime: Python
- Root directory: `backend/session-engine`
- Build: `pip install --upgrade pip && pip install -r requirements.txt`
- Start: `uvicorn main:app --host 0.0.0.0 --port $PORT`
- Health check: `/health`
- Readiness check: `/readyz`

## Neon database

1. Create a Neon project and database.
2. Copy the pooled connection string into `DATABASE_URL`.
3. Copy the direct connection string into `DIRECT_URL` only if you configure it.
4. Use `sslmode=require` or Neon's complete required query parameters.

Do not commit Neon credentials.

## Core API environment variables

Server:

- `NODE_ENV=production`
- `HOST=0.0.0.0`
- `API_VERSION=v1`
- `P1_SERVICE_TOKEN`
- `JWT_ACCESS_SECRET`
- `JWT_REFRESH_SECRET`
- `JWT_ACCESS_EXPIRY=15m`
- `JWT_REFRESH_EXPIRY=7d`

Database:

- `DATABASE_URL`
- `DIRECT_URL`

Application URLs:

- `CLIENT_URL`
- `ADMIN_URL`
- `ALLOWED_ORIGINS`

Demo and payment controls:

- `MOCK_SERVICES_ENABLED=false`
- `MOCK_DEMO_MODE=false`
- `MOCK_PAYMENT_ADMIN_TOKEN`

Google OAuth:

- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `GOOGLE_CALLBACK_URL`

Apple OAuth:

- `APPLE_CLIENT_ID`
- `APPLE_TEAM_ID`
- `APPLE_KEY_ID`
- `APPLE_PRIVATE_KEY_PATH`
- `APPLE_CALLBACK_URL`

Email:

- `SENDGRID_API_KEY`
- `SENDGRID_FROM_EMAIL`

Render supplies `PORT`; do not set a fixed value.

## Session Engine environment variables

- `APP_ENV=production`
- `HOST=0.0.0.0`
- `P1_BASE_URL=https://CORE-API-HOST/api/v1`
- `P1_SERVICE_TOKEN` (exactly the Core API value)
- `P1_TIMEOUT_SECONDS=10`
- `VIDEO_PROVIDER=agora`
- `AGORA_APP_ID`
- `AGORA_APP_CERTIFICATE`
- `VIDEO_TOKEN_TTL_SECONDS=600`
- `STRICT_TIER_REVERIFY=true`
- `DEV_MOCK_DATA=false`

## Prisma migrations

Deploy migrations from the Core API Render Shell:

```bash
npx prisma migrate deploy
```

Do not use `prisma migrate dev` or reset commands in production.

## Deployment order

1. Push the repository to GitHub.
2. Create the Core API Render service from `render.yaml`.
3. Enter all Core API secret environment variables.
4. Deploy and verify `/health`, `/livez`, and `/readyz`.
5. Run `npx prisma migrate deploy`.
6. Create or deploy the Session Engine.
7. Set `P1_BASE_URL` and the matching `P1_SERVICE_TOKEN`.
8. Verify Session Engine health and readiness.
9. Deploy Flutter with production `--dart-define` values.

## Flutter production build

```text
flutter build apk --release \
  --dart-define=PRODUCTION=true \
  --dart-define=CORE_API_BASE_URL=https://CORE-API-HOST/api/v1 \
  --dart-define=SESSION_ENGINE_BASE_URL=https://SESSION-HOST \
  --dart-define=AGORA_APP_ID=YOUR_AGORA_APP_ID
```

Do not pass the Agora certificate or any backend secret into Flutter.
Production URLs must use HTTPS.

## Health verification

Core API:

- `/health`
- `/livez`
- `/readyz`

Session Engine:

- `/health`
- `/livez`
- `/readyz`

## Common startup errors

- `Cannot find module '@/app'`: rebuild the Core API; the build step must
  run `node scripts/rewrite-path-aliases.cjs`.
- Missing environment variable: compare the service environment against
  this document and check Zod startup errors.
- Database not ready: verify Neon credentials and SSL parameters.
- Session readiness 503: verify `P1_BASE_URL` and `P1_SERVICE_TOKEN`.
- Agora join failure: verify the server-side App ID and certificate.

## Redeployment

Commit and push to the `main` branch. Render automatically redeploys
services configured with auto-deploy when the GitHub branch changes.
