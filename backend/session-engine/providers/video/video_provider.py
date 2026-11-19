"""
VideoProvider interface (Phase 0/4).

"No provider-specific SDK calls should exist outside AgoraProvider after
this phase — verify with a grep audit" (Section 8). Every other manager in
this codebase talks only to this interface, never to `agora_provider`
directly, so swapping providers later (Twilio/Stream) means writing one new
file, not touching SessionManager/VideoManager call sites.
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass


@dataclass
class VideoToken:
    token: str
    channel_name: str
    uid: str
    expires_at: float


class VideoProvider(ABC):
    @abstractmethod
    def create_room(self, session_id: str) -> str:
        """Returns a provider channel/room name for this session."""

    @abstractmethod
    def generate_token(self, *, channel_name: str, user_id: str, ttl_seconds: int) -> VideoToken:
        """
        Issues a short-lived, single-use, session-scoped credential.
        Section 14: "No permanent provider secret ever ships inside the
        mobile app — only short-lived, single-use, session-scoped tokens."
        """

    @abstractmethod
    def revoke_room(self, channel_name: str) -> None:
        """Tears down/cleans up a room. Called on session completion or
        cancellation (RoomManager's responsibility to invoke this)."""

    @abstractmethod
    def estimated_cost_per_minute(self, participant_count: int) -> float:
        """Used for the Phase 1 POC cost comparison memo (Section 5)."""
