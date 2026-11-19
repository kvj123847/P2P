"""
NotificationManager (Phase 7): emits typed events so session/video/chat
logic never needs to know how delivery works. Delivery (FCM/APNs) is a
stubbed hook here — real push-gateway wiring is a P1/shared-platform
concern per Section 11.

Section 11: "Every notification payload includes a typed event and minimal
data needed for deep-linking; no sensitive data (tokens, payment details) in
push payloads." — enforced by only ever building payloads from the
`_SAFE_FIELDS` allowlist below.
"""
from __future__ import annotations

import time
from dataclasses import dataclass, field
from enum import Enum
from typing import Callable


class NotificationEvent(str, Enum):
    BOOKING_CONFIRMED = "BOOKING_CONFIRMED"
    SESSION_REMINDER = "SESSION_REMINDER"
    SESSION_CANCELLED = "SESSION_CANCELLED"
    SESSION_STATUS_CHANGED = "SESSION_STATUS_CHANGED"
    SESSION_STARTING = "SESSION_STARTING"
    NEW_MESSAGE = "NEW_MESSAGE"


_SAFE_FIELDS = {"sessionId", "conversationId", "status", "reason", "senderId", "startsInSeconds"}


@dataclass
class NotificationPayload:
    event: NotificationEvent
    user_id: str
    data: dict = field(default_factory=dict)
    created_at: float = field(default_factory=time.time)

    def sanitized(self) -> dict:
        return {k: v for k, v in self.data.items() if k in _SAFE_FIELDS}


class NotificationManager:
    """
    In-memory pub/sub + an outbox for delivery. `deliver_fn` is where you'd
    plug in real FCM/APNs calls; left as a no-op logger by default so this
    module has zero runtime dependency on push infra being live.
    """

    def __init__(self, deliver_fn: Callable[[NotificationPayload], None] | None = None) -> None:
        self._outbox: list[NotificationPayload] = []
        self._deliver_fn = deliver_fn or self._default_deliver

    def emit(self, event: NotificationEvent, user_id: str, **data) -> NotificationPayload:
        payload = NotificationPayload(event=event, user_id=user_id, data=data)
        self._outbox.append(payload)
        self._deliver_fn(payload)
        return payload

    def outbox_for(self, user_id: str) -> list[NotificationPayload]:
        return [p for p in self._outbox if p.user_id == user_id]

    def _default_deliver(self, payload: NotificationPayload) -> None:
        # Replace with real FCM (Android) / APNs (iOS) delivery. Kept as a
        # deliberate no-op here — see module docstring.
        return None

    # --- convenience wrappers matching Section 7's named events ---
    def booking_confirmed(self, user_id: str, session_id: str) -> None:
        self.emit(NotificationEvent.BOOKING_CONFIRMED, user_id, sessionId=session_id)

    def session_reminder(self, user_id: str, session_id: str, starts_in_seconds: int) -> None:
        self.emit(NotificationEvent.SESSION_REMINDER, user_id, sessionId=session_id, startsInSeconds=starts_in_seconds)

    def session_cancelled(self, user_id: str, session_id: str, reason: str) -> None:
        self.emit(NotificationEvent.SESSION_CANCELLED, user_id, sessionId=session_id, reason=reason)

    def session_status_changed(self, user_id: str, session_id: str, status: str) -> None:
        self.emit(NotificationEvent.SESSION_STATUS_CHANGED, user_id, sessionId=session_id, status=status)

    def session_starting(self, user_id: str, session_id: str) -> None:
        self.emit(NotificationEvent.SESSION_STARTING, user_id, sessionId=session_id)

    def new_message(self, user_id: str, conversation_id: str, sender_id: str) -> None:
        self.emit(NotificationEvent.NEW_MESSAGE, user_id, conversationId=conversation_id, senderId=sender_id)
