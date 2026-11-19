"""
GET/POST /conversations/:id/messages — cursor pagination, tier check
inherited from session (Section 19).
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, Query

from core.auth import get_current_identity
from deps import get_chat_manager
from integrations.p1_client import Identity
from schemas.chat_schemas import (
    CreateConversationRequest,
    MarkReadRequest,
    MessageResponse,
    SendMessageRequest,
)
from services.chat_manager import ChatManager

router = APIRouter(prefix="/conversations", tags=["chat"])


@router.post("", status_code=201)
async def create_conversation(
    body: CreateConversationRequest,
    identity: Identity = Depends(get_current_identity),
    chat: ChatManager = Depends(get_chat_manager),
):
    convo = await chat.get_or_create_conversation(
        conversation_id=None,
        session_id=body.session_id,
        participant_ids=body.participant_ids,
        tier=body.tier,
    )
    return {"id": convo.id, "sessionId": convo.session_id, "participantIds": convo.participant_ids}


@router.post("/{conversation_id}/messages", response_model=MessageResponse, status_code=201)
async def send_message(
    conversation_id: str,
    body: SendMessageRequest,
    identity: Identity = Depends(get_current_identity),
    chat: ChatManager = Depends(get_chat_manager),
):
    message = await chat.send_message(conversation_id=conversation_id, sender_id=identity.user_id, body=body.body)
    return MessageResponse(**message.to_public_dict())


@router.get("/{conversation_id}/messages", response_model=list[MessageResponse])
async def get_messages(
    conversation_id: str,
    before_message_id: str | None = Query(default=None),
    limit: int | None = Query(default=None),
    identity: Identity = Depends(get_current_identity),
    chat: ChatManager = Depends(get_chat_manager),
):
    """Cursor-based pagination, newest-first, ~30/page (Section 10)."""
    messages = chat.get_messages_page(conversation_id=conversation_id, before_message_id=before_message_id, limit=limit)
    return [MessageResponse(**m.to_public_dict()) for m in messages]


@router.post("/{conversation_id}/read", status_code=204)
async def mark_read(
    conversation_id: str,
    body: MarkReadRequest,
    identity: Identity = Depends(get_current_identity),
    chat: ChatManager = Depends(get_chat_manager),
):
    chat.mark_read(conversation_id=conversation_id, user_id=identity.user_id, up_to_message_id=body.up_to_message_id)
    return None
