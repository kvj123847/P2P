from __future__ import annotations

from pydantic import BaseModel


class CreateConversationRequest(BaseModel):
    session_id: str | None = None
    participant_ids: list[str]
    tier: str


class SendMessageRequest(BaseModel):
    body: str


class MessageResponse(BaseModel):
    id: str
    conversationId: str
    senderId: str
    body: str
    createdAt: float
    readBy: list[str]


class MarkReadRequest(BaseModel):
    up_to_message_id: str
