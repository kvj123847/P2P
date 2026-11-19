# Stage 1 Proposed Integration Map

## Scope and source preservation

The three original directories remain untouched. The normalized repository now
contains copied project roots; the original directories remain as preservation
copies until deletion approval.

| Responsibility | Integrated root | Authority |
|---|---|---|---|
| Core API, auth, users, roles, tutors, bookings, payments, review, Prisma | `backend/core-api/` | Users, age tier, booking, payment, review and persistent records |
| Session orchestration, rooms, presence, provider adapter, session chat events | `backend/session-engine/` | Transient room lifecycle and provider credentials after P1 approval |
| Flutter UI and client state | `mobile/` | Presentation only; no authorization authority |

## Proposed join flow

1. Flutter authenticates with Person 1 and stores the access token securely.
2. Flutter calls one agreed session-engine join endpoint with the bearer token.
3. Session engine forwards the bearer token plus session identifier to a new
   authenticated Person 1 authorization endpoint.
4. Person 1 verifies JWT, active account, role, authoritative age tier, session
   status, participant membership, booking status and payment eligibility.
5. Person 1 returns verified room/channel metadata and participant role.
6. Person 2 maps the verified user ID to a stable numeric RTC UID and generates
   a short-lived Agora RTC token server-side.
7. Flutter receives only the short-lived token/channel/UID and joins Agora.

The existing Person 1 `room-token` endpoint is authorization metadata only; the
existing Person 2 `/sessions/{id}/video-token` and `/join` endpoints are the
closest future client-facing surface. The final contract must choose one
endpoint and remove ambiguity rather than expose all three.

## API ownership decisions

- Auth/profile/roles/tutors/bookings/payments/review: Person 1 `/api/v1`.
- Room authorization: Person 1 internal service contract, authenticated with a
  service credential and the end-user bearer token.
- Session join/leave/participants/token renewal: Person 2.
- Persistent chat/conversation/message records: use Person 1 Prisma models;
  Person 2 may own WebSocket transport and transient presence.
- Courses, uploads, playback and progress: Person 1 only after actual routes and
  storage behavior are confirmed.
- Push notifications: one shared delivery implementation; no-op delivery must
  not be described as production-ready.

## Known mismatches to resolve in Stage 4

- Flutter `/sessions/:id/rtc-token` vs Person 2 `/sessions/:id/video-token`
  and Person 1 `/api/v1/sessions/:id/room-token`.
- Flutter `/chats` vs Person 2 `/conversations`.
- Flutter `/payments/order`, `/wallet` and `/tutor/earnings` vs Person 1
  `/payments/checkout`, `/payments/transactions` and `/payments/earnings`.
- Flutter course and notification routes are listed but not represented by the
  inspected Person 1 route inventory.
- Flutter has no service-specific base URL or secure token storage.

## Copy and exclusion result

The actual roots are now in their required destinations. Generated environments,
caches, IDE metadata and real `.env` files are excluded; manifests, tests,
Prisma schema, assets and useful documentation are retained.

## Stage 3 baseline blockers

- Install backend Node dependencies before running Jest/build.
- Install the session engine's declared async pytest plugin in the selected
  environment and rerun the suite.
- Resolve the Flutter `UserRole.canTeach` analyzer error.
- Generate Flutter platform folders only after the integrated `mobile/` root is
  created.
- Obtain approved Agora and deployment credentials later; never put them in
  source or Flutter.

## Safe next stage

The structural consolidation is complete. Integration changes, API decisions
and dependency additions should wait until the copied baseline is independently
validated.
