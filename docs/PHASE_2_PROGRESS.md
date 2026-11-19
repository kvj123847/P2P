# Phase 2 Progress

## Stage 1 — Current-state audit

Status: Complete

### Completed

- Inspected the integrated repository structure and service boundaries.
- Verified the Person 1 service-token and room-authorization boundary.
- Verified the HTTP P1 client and server-side Agora token-builder structure.
- Inspected Prisma models, route modules, session/chat/notification managers,
  WebSocket gateway, Flutter API client, session controller, mock state, and
  tests.
- Created [PHASE_2_CURRENT_STATE_AUDIT.md](./PHASE_2_CURRENT_STATE_AUDIT.md).

### Validation evidence

- Core API build: passed.
- Core API tests: 32 passed.
- Session-engine tests: 41 passed.
- Flutter analyzer: passed.
- Flutter widget tests: passed.

### Stage 1 findings

- Prisma models for chat and notifications exist, but there is no migration
  directory and no verified durable API implementation.
- P2 chat, notifications, and sessions remain process-memory based.
- Conversation and WebSocket membership authorization needs correction.
- Flutter service boundaries exist, but screens remain mock-data driven.
- Agora Flutter and FCM integrations are not implemented or device-verified.

## Stage 2 — Database and core API foundation

Status: Foundation complete; persistence application is blocked by missing
`DATABASE_URL`.

### Completed

- Added `CourseEnrollment` and `LessonProgress` Prisma models.
- Added `DeviceToken` for authenticated FCM device registration.
- Generated the initial baseline migration at
  `backend/core-api/prisma/migrations/20261112213000_baseline/migration.sql`.
- Added age-tier-scoped course listing/detail, tutor course creation, lesson
  creation/listing, enrollment, and lesson-progress endpoints.
- Added authenticated notification listing, unread filtering, read/read-all,
  device registration, and device removal endpoints.
- Added authenticated durable conversation, message history, send-message, and
  read-state endpoints with server-side membership and age-tier checks.
- Regenerated Prisma Client and confirmed the TypeScript build.

### Validation

- Core API Jest regression suite: 4 suites, 32 tests passed.
- Prisma client generation: passed.
- `prisma validate`: blocked because `DATABASE_URL` is not configured in the
  environment.

### Remaining for Stage 2

- Replace P2's in-memory chat store with the Person 1 durable chat boundary.
- Add P1 notification event writers and FCM delivery adapter.
- Apply the baseline migration against a PostgreSQL test database.
- Add focused course, progress, notification, chat, and persistence tests.

## Repository cleanup

Status: Complete

- Removed generated Node dependencies and build output from the workspace:
  `backend/core-api/node_modules` and `backend/core-api/dist`.
- Removed runtime logs from `backend/core-api/logs`.
- Removed Python cache directories and pytest cache from the session engine.
- Removed the generated Flutter plugin dependency file.
- Kept source files, tests, Prisma schema/migration, lockfiles, environment
  examples, and project-reference documentation.
- Updated the root ignore rules so `mobile/pubspec.lock` remains preservable.
