# Render and Neon Deployment

## Services

Create two Render Web Services:

1. Root directory `backend/core-api`
   - Build: `npm ci && npm run build`
   - Start: `npm start`
2. Root directory `backend/session-engine`
   - Build: `pip install -r requirements.txt`
   - Start: `uvicorn main:app --host 0.0.0.0 --port $PORT`

Use Neon for `DATABASE_URL`, run reviewed Prisma migrations from the core API
service, and configure the session engine's `P1_BASE_URL` to the deployed core
API URL.

## Required secrets

- Core API: `DATABASE_URL`, JWT secrets, Stripe and email settings,
  `P1_SERVICE_TOKEN`.
- Session engine: `P1_BASE_URL`, matching `P1_SERVICE_TOKEN`,
  `AGORA_APP_ID`, `AGORA_APP_CERTIFICATE`.

Never put the Agora certificate, Stripe secret, JWT secrets or service token in
Flutter or source control.

## Verification

Check `/health` and `/readyz` on both services, then verify an authenticated paid booking
cannot join before payment confirmation and can join only after Person 1 marks
the payment successful.

Render free services may cold-start and use ephemeral local storage. Do not
store persistent chat, uploads or authoritative records on the local
filesystem. This configuration is for a prototype demonstration, not reliable
public production hosting.

## Current implementation status

IMPLEMENTED: Render service definitions, health-check paths, and environment placeholders are now recorded in the repo.
TESTED LOCALLY: configuration structure has been reviewed; live deployment remains unverified.
BLOCKED BY EXTERNAL CREDENTIALS: Render project access, Neon credentials, Agora keys, and any required production API domains.

