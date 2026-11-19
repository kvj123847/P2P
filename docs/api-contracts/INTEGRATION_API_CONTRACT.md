# Integration API Contract

This contract defines the implemented Person 1 to Person 2 room-join boundary.
The existing service contracts are retained as references at:

- `backend/core-api/docs/API_CONTRACTS_P1_P2_P3.md`
- `docs/api-contracts/SESSION_ENGINE_EXISTING_API_CONTRACT.md`
- `docs/project-reference/integration-map.md`

## Secure join flow

1. Flutter calls `POST /sessions/:sessionId/video-token` on Person 2 with the
   end-user bearer token.
2. Person 2 calls Person 1
   `POST /api/v1/sessions/:sessionId/authorize-room` with the same bearer token
   and `X-Service-Token`.
3. Person 1 verifies identity, age tier, session status, participant/booking
   membership, and successful payment for paid sessions.
4. Person 2 generates the short-lived Agora credential and returns it to
   Flutter.

Person 1 is authoritative for identity, bookings, payments and age-tier
authorization. Person 2 must not trust client-supplied user IDs, roles,
payments or age tiers. The Flutter API client uses separate core and session
engine base URLs; unimplemented feature routes remain pending and are not
claimed as available.

## Implemented Person 1 content and notification endpoints

All endpoints require the authenticated user's bearer token. Person 1 derives
the user's age tier from the database.

| Method | URL | Purpose | Authorization |
|---|---|---|---|
| GET | `/api/v1/courses` | List published courses | Same age tier only |
| GET | `/api/v1/courses/:courseId` | Read course and lessons | Published and same tier, or owner |
| POST | `/api/v1/courses` | Create a course | Tutor profile; tier is server-derived |
| POST | `/api/v1/courses/:courseId/lessons` | Add a lesson | Course owner |
| GET | `/api/v1/courses/:courseId/lessons` | List lessons | Same-tier course access |
| POST | `/api/v1/courses/:courseId/enroll` | Enroll learner | Published, same tier |
| GET | `/api/v1/courses/:courseId/progress` | Read progress | Enrolled learner |
| PATCH | `/api/v1/courses/:courseId/lessons/:lessonId/progress` | Update completion | Enrolled learner and course lesson |
| GET | `/api/v1/notifications?unread=true` | Read own notifications | Authenticated user only |
| PATCH | `/api/v1/notifications/:notificationId/read` | Mark own notification read | Owner only |
| POST | `/api/v1/notifications/read-all` | Mark own notifications read | Authenticated user only |
| POST | `/api/v1/notifications/device-token` | Register FCM token | Authenticated user only |
| DELETE | `/api/v1/notifications/device-token` | Remove own FCM token | Owner only |

Course creation and lesson creation do not publish content. Existing mentor
review routes remain the only publication path.

## Implemented Person 1 chat endpoints

| Method | URL | Purpose | Authorization |
|---|---|---|---|
| POST | `/api/v1/conversations` | Create a same-tier conversation | Authenticated creator; participants verified server-side |
| GET | `/api/v1/conversations/:conversationId/messages` | Read cursor-based message history | Conversation member only |
| POST | `/api/v1/conversations/:conversationId/messages` | Persist a message | Conversation member only |
| POST | `/api/v1/conversations/:conversationId/read` | Update read timestamp | Conversation member only |

These endpoints are the durable source of truth. Person 2's WebSocket gateway
must use them for persistence and verify membership before accepting a
conversation socket.
