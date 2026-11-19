"""
session_participants entity (Section 18) + ConnectionState enum used by
ConnectionManager (Phase 4/11).
"""
from __future__ import annotations

import time
from dataclasses import dataclass, field
from enum import Enum


class ParticipantRole(str, Enum):
    TUTOR = "TUTOR"
    LEARNER = "LEARNER"


class ConnectionState(str, Enum):
    NOT_JOINED = "NOT_JOINED"
    CONNECTED = "CONNECTED"
    RECONNECTING = "RECONNECTING"
    DISCONNECTED = "DISCONNECTED"
    FAILED = "FAILED"


@dataclass
class Participant:
    session_id: str
    user_id: str
    role: ParticipantRole
    join_status: ConnectionState = ConnectionState.NOT_JOINED
    audio_on: bool = True
    video_on: bool = True
    joined_at: float | None = None
    left_at: float | None = None
    connection_state: ConnectionState = ConnectionState.NOT_JOINED
    disconnected_since: float | None = None

    def mark_joined(self) -> None:
        self.join_status = ConnectionState.CONNECTED
        self.connection_state = ConnectionState.CONNECTED
        self.joined_at = time.time()
        self.disconnected_since = None

    def mark_left(self) -> None:
        self.connection_state = ConnectionState.DISCONNECTED
        self.left_at = time.time()

    def mark_reconnecting(self) -> None:
        self.connection_state = ConnectionState.RECONNECTING
        if self.disconnected_since is None:
            self.disconnected_since = time.time()

    def mark_reconnected(self) -> None:
        self.connection_state = ConnectionState.CONNECTED
        self.disconnected_since = None

    def mark_failed(self) -> None:
        self.connection_state = ConnectionState.FAILED
        self.left_at = time.time()

    def to_public_dict(self) -> dict:
        return {
            "id": self.user_id,
            "role": self.role.value,
            "audioOn": self.audio_on,
            "videoOn": self.video_on,
            "connectionState": self.connection_state.value,
        }
