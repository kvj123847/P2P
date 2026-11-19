# Person 1 Backend Analysis

## Inspected root

`backend/core-api/`

This is the normalized Person 1 project root.

## Technology and dependencies

- Node.js, TypeScript, Express 4, Prisma 5, PostgreSQL.
- JWT authentication with bcrypt password hashing.
- Zod request validation, Helmet, CORS, compression, rate limiting, Winston/Morgan logging.
- Stripe and Stripe Connect payment dependencies; SendGrid/Nodemailer email dependencies.
- Redis, Socket.IO, OAuth Google/Apple, Multer and UUID dependencies are declared.
- Jest, Supertest, Prismock and ts-jest are used for tests.
- Build and runtime configuration are in `package.json`, `tsconfig.json`, `src/config/`,
  `Dockerfile*`, `docker-compose.yml`, and `backend/.env.example`.

## Implemented

- Express app, health checks, API version prefix, security middleware and error handling
  (`src/app.ts`).
- Local/OAuth authentication, refresh/logout, email verification and password reset
  routes (`src/modules/auth/`).
- DB-backed authentication middleware that re-checks account status, active roles and
  authoritative `ageTier` on every request (`src/middleware/auth.ts`).
- User profile and role management, tutor profiles/discovery, mentor review, payments,
  live session creation/listing/booking, audit logging and age-tier guards.
- Prisma schema includes users, roles, tutors, mentors, courses, lessons, reviews,
  live sessions, bookings, conversations, participants, messages, payments, earnings,
  payouts, notifications and audit logs (`prisma/schema.prisma`).
- Session creation locks the session to the tutor's DB age tier; listing and booking
  filter/check the same tier (`src/modules/sessions/sessions.service.ts`).
- Room authorization checks the user's DB tier and confirmed booking before returning
  room metadata (`src/modules/sessions/sessions.service.ts`).
- Tests cover authentication, age-tier behavior, payments and mentor review.

## Partially implemented or unsafe for integration

- `GET /api/v1/sessions/:sessionId/room-token` returns room authorization metadata,
  not an Agora credential. It must remain an authorization contract for Person 2,
  not be exposed as token generation.
- `bookSession` accepts an optional `paymentId` and creates a `CONFIRMED` booking
  directly. Payment fulfillment must be reconciled with Stripe confirmation before
  a paid booking is joinable.
- The session service does not yet expose a dedicated authenticated service-to-service
  authorization endpoint for Person 2, nor a documented response envelope tailored to
  the session engine.
- The schema has chat/course/payment models, but the inspected route inventory does not
  show mounted course, chat, notification or upload modules. Their availability must
  be verified before wiring Flutter.
- CORS currently accepts any origin in the rejection branch for local mobile testing;
  this requires tightening for deployed environments.
- The declared Redis and Socket.IO dependencies do not by themselves prove that
  persistence or real-time delivery is wired.

## Placeholder or missing

- No verified end-to-end Person 1-to-Person 2 HTTP client contract was found.
- No Agora token generation belongs in this service; the current room endpoint must not
  be treated as one.
- Course publishing, file/video storage, learner progress, chat persistence and push
  delivery need endpoint-level confirmation or implementation.

## Must not be duplicated

Person 1 remains authoritative for identity, roles, age tier, booking, payment,
course-review authorization, session records and persistent user/booking/payment data.
Person 2 and Flutter must consume these decisions rather than maintain competing copies.

## Baseline validation

- Backend tests were not run because `node_modules` is absent in the inspected project.
- No source files were changed during inspection.
