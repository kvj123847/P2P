"""
ChatManager (Phase 6): conversation + message persistence, cursor
pagination, read state, and the same tier enforcement as video (inherited
from the session/conversation's tier, verified via P1Client at send time
for standalone chats with no session).

Section 10: "No polling — push over WebSocket, REST only for
backfill/pagination." This module is transport-agnostic; websocket/gateway.py
calls into it and pushes results over the socket, while api/chat.py exposes
the same operations over REST for backfill.
"""
from __future__ import annotations

from core.errors import NotAParticipantError, TierMismatchError, ValidationError
from integrations.p1_client import P1ClientInterface
from models.conversation import Conversation, Message


class ChatManager:
    def __init__(self, p1_client: P1ClientInterface, page_size: int = 30) -> None:
        self.p1_client = p1_client
        self.page_size = page_size
        self._conversations: dict[str, Conversation] = {}
        self._messages: dict[str, list[Message]] = {}  # conversation_id -> messages, oldest first

    async def get_or_create_conversation(
        self, *, conversation_id: str | None, session_id: str | None, participant_ids: list[str], tier: str
    ) -> Conversation:
        if conversation_id and conversation_id in self._conversations:
            return self._conversations[conversation_id]

        if not await self.p1_client.check_tier_compatible(participant_ids):
            raise TierMismatchError("Chat participants must share the same age tier.")

        convo = Conversation(session_id=session_id, participant_ids=participant_ids, tier=tier)
        self._conversations[convo.id] = convo
        self._messages[convo.id] = []
        return convo

    async def send_message(self, *, conversation_id: str, sender_id: str, body: str) -> Message:
        convo = self._conversations.get(conversation_id)
        if convo is None:
            raise ValidationError("Conversation does not exist.")
        if sender_id not in convo.participant_ids:
            raise NotAParticipantError("Sender is not a participant of this conversation.")
        if not body or not body.strip():
            raise ValidationError("Message body cannot be empty.")

        message = Message(conversation_id=conversation_id, sender_id=sender_id, body=body.strip())
        self._messages.setdefault(conversation_id, []).append(message)
        return message

    def get_messages_page(
        self, *, conversation_id: str, before_message_id: str | None = None, limit: int | None = None
    ) -> list[Message]:
        """
        Cursor-based pagination, newest-first for display, loaded in pages
        of ~30 on scroll-up (Section 10).
        """
        limit = limit or self.page_size
        all_messages = self._messages.get(conversation_id, [])
        if before_message_id is None:
            page = all_messages[-limit:]
        else:
            idx = next((i for i, m in enumerate(all_messages) if m.id == before_message_id), None)
            if idx is None:
                page = all_messages[-limit:]
            else:
                start = max(0, idx - limit)
                page = all_messages[start:idx]
        return list(reversed(page))  # newest-first

    def get_messages_since(self, *, conversation_id: str, last_received_message_id: str | None) -> list[Message]:
        """
        Used on WebSocket reconnect: "resume the WebSocket, then fetch any
        messages missed since lastReceivedMessageId via REST" (Section 10).
        """
        all_messages = self._messages.get(conversation_id, [])
        if last_received_message_id is None:
            return list(all_messages)
        idx = next((i for i, m in enumerate(all_messages) if m.id == last_received_message_id), None)
        if idx is None:
            return list(all_messages)
        return all_messages[idx + 1 :]

    def mark_read(self, *, conversation_id: str, user_id: str, up_to_message_id: str) -> None:
        for m in self._messages.get(conversation_id, []):
            m.read_by.add(user_id)
            if m.id == up_to_message_id:
                break
