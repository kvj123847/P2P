# Person 2 Session Engine Analysis

## Inspected root

`backend/session-engine/`

The Python/reference SDK is retained separately under
`docs/project-reference/mobile-video-sdk/`; it is not a Flutter production SDK.

## Technology and dependencies

- Python 3-style code, FastAPI, Uvicorn, Pydantic 2 and WebSockets.
- `httpx` is declared for the future HTTP integration, but no real P1 client is
  implemented in the inspected code.
- pytest and pytest-asyncio are declared in `requirements.txt`.
- Configuration is environment-driven through `core/config.py`.
- Service layers include session, room, participant, connection, video, chat and
  notification managers.

## Implemented

- FastAPI application with health endpoint, session routes, conversation routes,
  payment-status webhook shape and a WebSocket conversation gateway (`main.py`,
  `api/`, `websocket/`).
- Session state machine, one-to-one/group session models, expected participant
  tracking, capacity checks, join/leave/complete flow and idempotent
  booking-to-session mapping (`services/session_manager.py`).
- Security-oriented tests for tier mismatch, non-participants, capacity,
  invalid sessions, payment state and direct/UI bypass scenarios.
- Provider abstraction (`providers/video/video_provider.py`) and manager boundary
  that keeps provider-specific operations out of the session orchestration.
- In-memory chat conversations, cursor pagination/read state and WebSocket
  reconnection/backfill behavior.
- Notification event types and sanitized payload construction.

## Partially implemented

- `integrations/p1_client.py` is still `FakeP1Client`; all identity, booking,
  participant, tier and payment decisions are local test data.
- Session and chat state are process-local dictionaries/lists. Restarting the
  service loses sessions, participants, messages and notification outbox.
- `POST /webhooks/payment-status` is not authenticated as a Person 1 service
  webhook.
- User-facing auth accepts a bearer token but delegates verification to the fake
  client rather than validating Person 1 JWTs over a real HTTP call.
- Group-session creation accepts caller-supplied tutor, learners and tier; this
  must be replaced or constrained by Person 1 authorization.
- The notification delivery function is deliberately a no-op; FCM/APNs is not
  implemented.

## Placeholder or missing

- `providers/video/agora_provider.py` generates an HMAC placeholder token, not an
  Agora RTC token. The code explicitly defers the official token-builder package.
- `deps.py` selects a fake video provider when development credentials are used and
  includes a fake token implementation.
- No persistent database adapter, real P1 HTTP client, signed service webhook,
  production push provider, or durable chat repository was found.
- Media lifecycle is represented at the application layer; actual Flutter Agora
  joining is outside this codebase.

## Existing API surface

- `POST /sessions`, `POST /sessions/group`, `GET /sessions/{id}`.
- `POST /sessions/{id}/cancel`, `/start`, `/video-token`, `/join`, `/leave`,
  `/complete`, and `GET /sessions/{id}/participants`.
- `POST /conversations`, message send/list/read routes and
  `WS /ws/conversations/{conversation_id}`.
- `POST /webhooks/payment-status`.

These are not yet aligned with Person 1's `/api/v1` routes or the Flutter
placeholder paths.

## Must not be duplicated

Person 2 should own transient room/session orchestration, participant presence,
video-provider token creation and session events. It must not own users, roles,
age-tier storage, booking/payment truth or authoritative authorization.

## Baseline validation

`python -m pytest -q` was attempted. Result: 20 passed, 21 failed, 22 warnings.
The failures report that async test functions are unsupported by the active
environment, despite the plugin being listed in `requirements.txt`; the suite
therefore needs its environment repaired before code-level conclusions are made.
No source files were changed during inspection.
