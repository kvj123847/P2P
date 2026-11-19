# Peer Learning Platform

Integrated repository for the peer-to-peer student learning platform.

## Repository layout

```text
backend/
  core-api/         Node.js, Express, TypeScript, Prisma, PostgreSQL
  session-engine/   Python, FastAPI, session orchestration and video adapter
mobile/             Flutter application
docs/               Architecture, contracts, security, deployment and references
tests/              Cross-service integration and end-to-end tests
```

## Ownership

- `backend/core-api` is authoritative for identity, roles, age tier, bookings,
  payments, tutor data and mentor-review decisions.
- `backend/session-engine` owns transient room lifecycle, participant presence,
  session events and provider credentials only after core API authorization.
- `mobile` is the client UI and must not make authorization decisions.

## Current status

The integrated codebase is locally validated and has production hardening scaffolding in place,
but external deployment credentials and physical-device verification remain required.

The repository now includes production-oriented configuration defaults, Render deployment templates,
health/readiness endpoints, explicit CORS allowlists, and environment placeholders for Neon/Render.
See the deployment and testing documentation in `docs/` before moving to a live production deployment.

## Source preservation

The original extracted directories remain beside this repository until the
deletion candidates are reviewed and approved.

