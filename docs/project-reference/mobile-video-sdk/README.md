# mobile-video-sdk — integration contract for Person 3

This is the facade Person 3's mobile screens call. Per Section 20 of the
roadmap, Person 3 should never call the video provider SDK (Agora, etc.)
directly, and never call session-engine REST endpoints directly for
call/session state — only through this package.

```python
from mobile_video_sdk import SessionController

controller = SessionController(base_url="https://session-engine.internal", bearer_token=user_token)

controller.events.on("sessionState", lambda s: print("session ->", s))
controller.events.on("connectionState", lambda s: print("connection ->", s))
controller.events.on("participants", lambda p: print("roster ->", p))
controller.events.on("errorState", lambda e: print("error ->", e))

controller.join_session("session-id-123")
controller.toggle_microphone()
controller.toggle_camera()
controller.leave_session()
```

## Porting to React Native / Flutter

This Python module is the **reference implementation** of the contract —
port it 1:1 to TypeScript (RN) or Dart (Flutter):

- `join_session(sessionId)` / `leave_session()` / `toggle_camera()` /
  `toggle_microphone()` stay the same method names and behavior.
- `state` is a single object the screen renders from — never read
  provider-SDK state directly.
- Every state change is also emitted as an event on `events` so a screen can
  subscribe once and re-render on any change, rather than polling.

## What this does NOT do

- It does not touch Agora/Twilio/Stream SDKs — that only happens inside
  `session-engine/providers/video/`, on the server.
- It does not decide whether a join is authorized — the server's secure
  join flow (Section 14) does that; this package just surfaces the result
  (a credential or an error) to the UI.
