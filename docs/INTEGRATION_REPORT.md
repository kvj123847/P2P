# Integration Report

## Completed

- Consolidated the three projects into `backend/core-api`, `backend/session-engine`
  and `mobile`.
- Preserved existing internal source layouts, tests, manifests and Prisma schema.
- Added root documentation, environment examples, security model and deployment
  guidance.
- Added a service-authenticated Person 1 room-authorization endpoint.
- Added payment-aware room authorization so paid sessions require a successful
  session payment.
- Added a real HTTP P1 client boundary in the session engine.
- Replaced the HMAC placeholder Agora token with the official token-builder API
  and stable numeric UID mapping.
- Added Flutter HTTP and secure-storage dependencies, a dual-base-URL API
  client, and a reusable session controller for the session-engine token flow.
- Added durable course enrollment, lesson progress, and device-token models with
  a Prisma baseline migration.
- Added authenticated Person 1 course/lesson/progress and notification APIs.

## Modified files

- Core API environment, service middleware, session routes/controller/service and
  payment fulfillment.
- Session engine configuration, dependency composition, P1 client, join flow,
  API headers, Agora provider and requirements.
- Flutter package name and test imports.
- Integration, architecture, security and deployment documentation.

## Pending

- Wiring the Flutter API client into every existing mock-data screen and adding
  the Agora Flutter SDK/UI adapter.
- Persistent chat repository and push notification delivery.
- Applying the Prisma baseline migration requires a configured PostgreSQL
  `DATABASE_URL`.
- Course routes/uploads/playback/progress where missing.
- Full cross-service integration tests.

## External requirements

Agora credentials, Stripe/Neon/Render accounts, HTTPS deployment URLs and
physical Android devices are required for end-to-end verification.
