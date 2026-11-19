"""
Typed events/state Person 3 subscribes to (Section 20). Mirrors the
observable state described in the roadmap:

    sessionState, connectionState, participants, localVideoState,
    remoteVideoState, microphoneState, cameraState, errorState

In a real React Native/Flutter app this would be a native-module-agnostic
JS/Dart package. This Python version exists so the same event-driven
contract can be exercised, demoed, and unit-tested from Python (e.g. a
desktop reference client, or Person 3's own test harness) using the exact
shape Person 3 will integrate against.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Callable


class SessionState(str, Enum):
    CREATED = "CREATED"
    PENDING_PAYMENT = "PENDING_PAYMENT"
    CONFIRMED = "CONFIRMED"
    SCHEDULED = "SCHEDULED"
    WAITING = "WAITING"
    LIVE = "LIVE"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"
    FAILED = "FAILED"


class ConnectionState(str, Enum):
    NOT_JOINED = "NOT_JOINED"
    CONNECTED = "CONNECTED"
    RECONNECTING = "RECONNECTING"
    DISCONNECTED = "DISCONNECTED"
    FAILED = "FAILED"


@dataclass
class ParticipantState:
    id: str
    role: str
    audioOn: bool
    videoOn: bool
    connectionState: str


@dataclass
class SdkState:
    """The single object Person 3 renders their call screen from — "Person 3
    subscribes once per screen and renders purely from state, never
    reaching into the provider SDK" (Section 20)."""

    session_state: SessionState = SessionState.CREATED
    connection_state: ConnectionState = ConnectionState.NOT_JOINED
    participants: list[ParticipantState] = field(default_factory=list)
    local_video_on: bool = True
    local_audio_on: bool = True
    error_state: str | None = None


class EventEmitter:
    """Minimal typed pub/sub so SessionController can notify subscribers
    (Person 3's UI layer) without them touching the provider SDK."""

    def __init__(self) -> None:
        self._listeners: dict[str, list[Callable]] = {}

    def on(self, event_name: str, callback: Callable) -> None:
        self._listeners.setdefault(event_name, []).append(callback)

    def off(self, event_name: str, callback: Callable) -> None:
        if event_name in self._listeners:
            self._listeners[event_name] = [cb for cb in self._listeners[event_name] if cb != callback]

    def emit(self, event_name: str, *args, **kwargs) -> None:
        for cb in self._listeners.get(event_name, []):
            cb(*args, **kwargs)
