# API Contract with Person 1 — Proposed, needs sign-off

Mirrors `person2-roadmap.pdf` Section 19. Implemented in `api/sessions.py`,
`api/video.py`, `api/chat.py`, `api/notifications.py`.

| API | Method / Endpoint | Auth | Owner | Notes |
|---|---|---|---|---|
| Create session | `POST /sessions` | Bearer | P2 (endpoint), P1 (tier check) | Idempotent via `booking_id` |
| Get session | `GET /sessions/:id` | Bearer | P2 | 404 vs 403 must not leak existence |
| Book session | `POST /bookings` | Bearer | P1 (booking+payment), P2 (session creation trigger) | 409 on duplicate booking |
| Cancel session | `POST /sessions/:id/cancel` | Bearer | P2 | 403 if not owner/participant |
| Start session | `POST /sessions/:id/start` | Bearer | P2 | Only valid from WAITING |
| Get video credentials | `POST /sessions/:id/video-token` | Bearer | P1 (issues, verifies tier), P2 (consumes) | TTL ~5-10 min |
| Join session | `POST /sessions/:id/join` | Bearer | P2 | Emits PARTICIPANT_JOINED |
| Leave session | `POST /sessions/:id/leave` | Bearer | P2 | Idempotent |
| Complete session | `POST /sessions/:id/complete` | System/Bearer | P2 | Terminal state, triggers earnings event for P1 |
| Get participants | `GET /sessions/:id/participants` | Bearer | P2 | Participant-only visibility |
| Conversation/messages | `GET/POST /conversations/:id/messages` | Bearer | P2 | Cursor pagination, tier inherited from session |
| Notifications | `GET /notifications` | Bearer | P2 (events), P1 (push infra if shared) | — |

**Not yet in this repo, requires P1's real `POST /bookings` endpoint**:
`create_session_from_booking()` currently expects a `booking_id` that
`P1Client.get_booking()` can resolve. Swap `FakeP1Client` for a real HTTP
client once P1's booking API is live — no other code changes needed.

All error responses follow the shared envelope defined in `core/errors.py`:
`{"error": {"code": "...", "message": "..."}}`.
