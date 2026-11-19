# Production Environment Reference

## Status

IMPLEMENTED: environment structuring and placeholders prepared in repo.
TESTED LOCALLY: environment validation in local dev/test mode.
DEPLOYED: not yet deployed.
VERIFIED ON PHYSICAL DEVICE: not yet.
BLOCKED BY EXTERNAL CREDENTIALS: live service URLs, secrets, and deployment account access.

## Core API required variables

- `NODE_ENV=production`
- `HOST=0.0.0.0`
- `PORT=3000`
- `API_VERSION=v1`
- `DATABASE_URL`
- `DIRECT_URL`
- `JWT_ACCESS_SECRET`
- `JWT_REFRESH_SECRET`
- `P1_SERVICE_TOKEN`
- `CLIENT_URL`
- `ADMIN_URL`
- `ALLOWED_ORIGINS`
- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `GOOGLE_CALLBACK_URL`
- `APPLE_CLIENT_ID`
- `APPLE_TEAM_ID`
- `APPLE_KEY_ID`
- `APPLE_PRIVATE_KEY_PATH`
- `APPLE_CALLBACK_URL`
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `STRIPE_CONNECT_WEBHOOK_SECRET`
- `SENDGRID_API_KEY`
- `SENDGRID_FROM_EMAIL`

## Session engine required variables

- `APP_ENV=production`
- `HOST=0.0.0.0`
- `PORT=8001`
- `P1_BASE_URL`
- `P1_SERVICE_TOKEN`
- `P1_TIMEOUT_SECONDS=10`
- `VIDEO_PROVIDER=agora`
- `AGORA_APP_ID`
- `AGORA_APP_CERTIFICATE`
- `VIDEO_TOKEN_TTL_SECONDS=600`
- `STRICT_TIER_REVERIFY=true`
- `DEV_MOCK_DATA=false`

## Deployment rules

- Never use localhost or 127.0.0.1 in production service URLs.
- Use the internal private network name or Render service URL for service-to-service communication.
- Keep all secrets in Render environment variables only.
- Keep Flutter and client apps free of API secrets or Agora certificates.
- Use structured logging and safe health endpoints without exposing system internals.
