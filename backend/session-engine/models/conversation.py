"""
conversations + messages entities (Section 18), owned in storage by Person 1
but read/written through ChatManager's APIs, per Section 10.
"""
from __future__ import annotations

import time
import uuid
from dataclasses import dataclass, field


@dataclass
class Conversation:
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    session_id: str | None = None  # nullable for standalone chat, Section 18
    participant_ids: list[str] = field(default_factory=list)
    tier: str = ""
    created_at: float = field(default_factory=time.time)


@dataclass
class Message:
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    conversation_id: str = ""
    sender_id: str = ""
    body: str = ""
    created_at: float = field(default_factory=time.time)
    read_by: set[str] = field(default_factory=set)

    def to_public_dict(self) -> dict:
        return {
            "id": self.id,
            "conversationId": self.conversation_id,
            "senderId": self.sender_id,
            "body": self.body,
            "createdAt": self.created_at,
            "readBy": sorted(self.read_by),
        }
