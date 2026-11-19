# Production Environment Variables

Configure these in the Render service environment settings, not in source control or chat.

## Core API

Required:

- `NODE_ENV=production`
- `HOST=0.0.0.0`
- `PORT` (Render supplies this; do not hard-code it)
- `API_VERSION=v1`
- `DATABASE_URL` (Neon pooled connection string)
- `P1_SERVICE_TOKEN` (at least 32 random characters)
- `JWT_ACCESS_SECRET` and `JWT_REFRESH_SECRET` (at least 32 random characters each)
- `JWT_ACCESS_EXPIRY=15m`
- `JWT_REFRESH_EXPIRY=7d`
- `ALLOWED_ORIGINS` (comma-separated exact origins)
- `CLIENT_URL` and `ADMIN_URL`
- The existing OAuth and SendGrid variables if those flows are enabled.

Demo-only:

- `MOCK_SERVICES_ENABLED=false` for a normal production service.
- `MOCK_DEMO_MODE=false`.
- `MOCK_PAYMENT_ADMIN_TOKEN` (at least 32 random characters). This is required by the server even when mock operations are disabled.

Stripe and Firebase credentials are intentionally not required.

## Session Engine

- `APP_ENV=production`
- `HOST=0.0.0.0`
- `PORT` (Render supplies this)
- `P1_BASE_URL` (the deployed Core API URL)
- `P1_SERVICE_TOKEN` (the same value as Core API)
- `P1_TIMEOUT_SECONDS=10`
- `VIDEO_PROVIDER=agora`
- `AGORA_APP_ID`
- `AGORA_APP_CERTIFICATE`
- `VIDEO_TOKEN_TTL_SECONDS=600`
- `STRICT_TIER_REVERIFY=true`
- `DEV_MOCK_DATA=false`

Never put `AGORA_APP_CERTIFICATE`, JWT secrets, database URLs, or service tokens in Flutter.

