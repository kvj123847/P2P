# Phase 2 Current-State Audit

Date: 2026-11-12

This audit compares the supplied Phase 2 status with the repository as
implemented. Stage 1 was inspection-only; no application code was changed.

## 1. Verified completed features

### Repository and service boundaries

- The integrated repository is present under `backend/core-api`,
  `backend/session-engine`, `mobile`, `docs`, and `tests`.
- Person 1 remains the intended authority for users, age tiers, bookings,
  payments, sessions, courses, and mentor review.
- Person 2 has a separate FastAPI service and does not contain a second
  PostgreSQL/Prisma data layer.

### Person 1 to Person 2 authorization

- `backend/core-api/src/middleware/serviceAuth.ts` validates
  `X-Service-Token`.
- `POST /api/v1/sessions/:sessionId/authorize-room` is mounted in
  `backend/core-api/src/modules/sessions/sessions.routes.ts`.
- Room authorization verifies the authenticated user, session status, age-tier
  compatibility, participant/booking membership, and successful payment for
  paid sessions in `sessions.service.ts`.
- The payment fulfillment path uses a booking upsert rather than creating a
  duplicate booking.
- `backend/session-engine/integrations/p1_client.py` contains a real HTTP P1
  client and an explicit fake test client.
- The production session-manager path requires Person 1 authorization before
  generating video credentials.

### Agora server-side token boundary

- `providers/video/agora_provider.py` uses the official
  `agora-token-builder` package.
- App ID and certificate are read from server configuration.
- Tokens have a configured TTL and use deterministic numeric UID mapping.
- Production configuration does not silently select the fake provider.

### Existing validation evidence

- Core API TypeScript build passed with `npm run build`.
- Core API Jest suite passed: 4 suites and 32 tests.
- Session-engine pytest suite passed: 41 tests.
- Flutter dependency resolution, analyzer, and widget tests passed.
- These results do not prove cross-service, Agora, FCM, deployment, or
  physical-device behavior.

## 2. Partially implemented features

### Person 1 persistence and APIs

- The Prisma schema includes `Course`, `Lesson`, `ChatConversation`,
  `ChatParticipant`, `ChatMessage`, `Notification`, `LiveSession`, and
  `SessionBooking` models.
- The schema has no `prisma/migrations` directory. Migration history is
  therefore not available in the integrated repository and database
  reproducibility is not verified.
- Authentication, tutors, payments, sessions, roles, users, and mentor review
  modules have routes and controllers.
- Course, chat, and notification models are not mounted as complete Person 1
  route modules.

### Session engine

- Sessions, participants, chat, and notification outboxes are held in Python
  process memory.
- Session lifecycle transitions exist in the engine model, but important
  lifecycle state is not persisted back to Person 1 for restart recovery.
- The engine has REST chat routes, notification listing, and a WebSocket
  gateway, but these operate against the in-memory managers.
- Agora provider code exists, but no real Agora credential or device validation
  has been performed.

### Flutter

- `mobile/lib/services/api_service.dart` now has a dual-base-URL HTTP client
  and secure access-token storage.
- `mobile/lib/services/session_controller.dart` obtains session-engine video
  credentials and exposes basic connection/camera/microphone state.
- Existing screens and `AppState` still use mock data and local state.
- No feature repositories are present and no authentication, tutor, booking,
  course, chat, notification, or payment screen is wired to live responses.
- The session controller does not initialize an Agora Flutter engine or render
  local/remote video.

## 3. Missing features

- P2 durable-chat adapter and WebSocket persistence bridge to Person 1.
- Conversation retrieval/listing and offline history integration across P1/P2.
- Persistent notification retrieval/read state and actual FCM delivery.
- Person 1 course and lesson APIs now exist; migration application and focused
  persistence tests remain.
- Flutter feature repositories and live screen integration.
- Agora Flutter SDK, permissions, engine lifecycle, rendering, renewal, and
  reconnection.
- Complete cross-service integration tests and end-to-end tests.
- Render/Neon deployment execution and physical Android testing.

## 4. Existing bugs and security defects

### High priority

1. `HttpP1Client.check_tier_compatible()` returns `len(user_ids) <= 1`
   instead of asking Person 1 to authorize all participants. This is not a
   valid group-chat/group-session authorization implementation.
2. `HttpP1Client.is_session_participant()` always returns `False`, so it
   cannot support a real participant authorization fallback.
3. `ChatManager.get_or_create_conversation()` trusts client-supplied
   participant IDs and tier after only a limited compatibility check.
4. REST message retrieval and read endpoints do not explicitly verify that
   the authenticated user belongs to the conversation before reading or
   marking messages.
5. The WebSocket gateway verifies the bearer token but accepts the socket
   without a Person 1-backed conversation membership check. A client can
   attempt to access a conversation by changing the path ID.
6. Chat and notification records disappear when the session-engine process
   restarts.

### Medium priority

1. The session engine has an in-memory `_sessions` map, so its session state
   cannot survive restart and is not authoritative.
2. The Flutter API client catches API-shaped failures but does not yet provide
   a shared network/JSON decoding error boundary or refresh-token flow.
3. The root and service environment examples use different local session
   engine ports (`8001` in the root example and `8000` in the Flutter client).
4. Core API CORS handling is intentionally permissive for local testing and
   should be restricted before public deployment.
5. The existing contract documents still describe the integration contract as
   proposed/placeholder in places, while the room authorization endpoint is
   implemented.

## 5. API mismatches

| Area | Current mismatch | Required correction |
|---|---|---|
| Session join | Flutter calls the session engine directly, while Person 1 exposes room authorization metadata | Keep one client-facing P2 `POST /sessions/:id/video-token`; document P2-to-P1 authorization as internal |
| Chat | Flutter legacy names use `/chats`; P2 exposes `/conversations` | Select `/conversations` as the P2 transport contract or add a documented adapter, not competing semantics |
| Payments | Flutter legacy names `/payments/order`, `/wallet`, `/tutor/earnings`; P1 exposes checkout/earnings routes | Map repositories to the actual P1 routes and mark unsupported operations pending |
| Courses | Flutter has course screens; P1 has models but no mounted course route module | Implement P1 course/lesson/progress routes before wiring live screens |
| Notifications | P2 has in-memory `GET /notifications`; P1 has a Notification model but no mounted notification routes | Make P1 the durable notification authority and retain P2 only for transient event delivery |
| Group authorization | P2 group creation accepts client-supplied tier and participant IDs | Require a P1 authorization response for the complete participant set |

## 6. Database gaps

- No Prisma migration history is present under
  `backend/core-api/prisma/migrations`.
- The schema has no explicit durable device-token model for FCM registration.
- Notification storage exists in the schema, but no verified service/controller
  persists or reads those records.
- Chat storage exists in the schema, but no verified service/controller is
  mounted for conversation/message operations.
- Course progress has no visible model in the inspected schema; a progress
  migration/model is required before claiming persisted lesson progress.
- Render/Neon readiness cannot be verified without applying migrations against a
  real PostgreSQL database.

## 7. Security concerns

- Never trust client-supplied `tier`, role, participant IDs, booking status, or
  payment status. The current group conversation/session paths need stronger
  P1-backed validation.
- Do not issue Agora credentials before the P1 room authorization result.
- WebSocket authentication must include conversation membership and
  age-tier authorization before `accept()`.
- Notification reads must be scoped by authenticated user ID.
- The permissive development CORS callback must be replaced with an explicit
  production allowlist.
- Secrets are represented by placeholders in environment examples; actual
  Agora, Stripe, JWT, service-token, database, and Firebase credentials remain
  external requirements and must not enter Flutter or source control.

## 8. Dependencies and credentials required

### Immediate code dependencies

- Prisma migration generation/application against PostgreSQL.
- Flutter `agora_rtc_engine` and Android permission configuration.
- Firebase Core and Firebase Messaging for FCM.
- A persistent notification/device-token implementation in Person 1.

### External credentials/services

- PostgreSQL/Neon `DATABASE_URL`.
- Person 1 JWT and service-token secrets.
- Agora App ID and App Certificate.
- Stripe keys and webhook secrets.
- Firebase Android configuration and server-side FCM credentials.
- Render service URLs and deployment access.
- Physical Android devices for real media, notification, and reconnection tests.

## 9. Recommended implementation order

1. Resolve the database baseline: create reviewed Prisma migrations and add
   only the minimum missing persistence models.
2. Implement Person 1 durable chat, notification, course, lesson, and progress
   APIs with age-tier and ownership enforcement.
3. Replace P2 chat/notification persistence with an HTTP repository boundary;
   retain only transient presence and WebSocket fan-out in P2.
4. Fix P2 conversation and group authorization so membership is P1-backed
   before REST/WebSocket access.
5. Expand integration/security tests for persistence, membership, and restart
   behavior.
6. Add Flutter repositories and connect authentication, tutors, booking,
   courses, chat, notifications, and payments incrementally.
7. Integrate Agora Flutter using `SessionController`, then add device tests.
8. Add FCM registration/delivery and device-token cleanup.
9. Run full end-to-end tests, then prepare Render/Neon deployment.

## 10. Immediate versus blocked work

### Can be implemented immediately

- Person 1 route/service/controller work for courses, chat, notifications,
  progress, and device-token registration.
- Prisma migration creation and database-backed tests, once a PostgreSQL test
  database is available.
- P2 membership checks, P1 client contract additions, and persistence adapters.
- Flutter repository scaffolding and live API wiring.
- Code-level Agora and FCM integration structure.
- Automated security and contract tests using fakes/test doubles.

### Blocked or externally dependent

- Applying and validating migrations against Neon without a database URL.
- Real Agora token/channel/media verification without Agora credentials.
- FCM delivery verification without Firebase configuration and an Android
  device.
- Render deployment verification without accounts, URLs, and secrets.
- Physical reconnection, camera/microphone, group-capacity, and release APK
  validation without devices.

## Stage 1 conclusion

The supplied status is directionally correct but optimistic about chat and
notification security and persistence. The repository is ready for Stage 2
implementation only after approval of the database/API ownership plan above.
No application code was modified during this audit.
