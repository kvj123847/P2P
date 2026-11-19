# Render Deployment Guide

## Core API

1. Create a Web Service from the repository.
2. Set root directory to `backend/core-api`.
3. Use Node runtime.
4. Build command: `npm ci --include=dev && npx prisma generate && npm run build`.
5. Start command: `npm start`.
6. Health check path: `/health`.
7. Add the Core API variables from [PRODUCTION_ENVIRONMENT_VARIABLES.md](./PRODUCTION_ENVIRONMENT_VARIABLES.md).
8. Set `DATABASE_URL` to the Neon pooled URL.

## Session Engine

1. Create a second Web Service from the same repository.
2. Set root directory to `backend/session-engine`.
3. Use Python runtime.
4. Build command: `pip install --upgrade pip && pip install -r requirements.txt`.
5. Start command: `uvicorn main:app --host 0.0.0.0 --port $PORT`.
6. Health check path: `/health`.
7. Set `P1_BASE_URL` to the actual Core API URL after the first service deploys.
8. Add Agora credentials only to this service.

Do not copy the placeholder domains from `render.yaml`; replace them with URLs Render assigns after deployment.

