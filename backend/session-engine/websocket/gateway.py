"""
Chat + live-event WebSocket gateway (Section 10):
  - authenticated with the same short-lived credential model as video
  - push over WebSocket, REST only for backfill/pagination
  - on reconnect: resume the socket, then fetch anything missed via REST
    (`ChatManager.get_messages_since`) rather than trusting the socket alone
"""
from __future__ import annotations

import json

from fastapi import WebSocket, WebSocketDisconnect

from core.errors import SessionEngineError
from integrations.p1_client import get_p1_client
from services.chat_manager import ChatManager


class ConnectionRegistry:
    """Tracks which user_id is on which live socket, per conversation, so
    NotificationManager/ChatManager can push without polling."""

    def __init__(self) -> None:
        self._sockets: dict[str, dict[str, WebSocket]] = {}  # conversation_id -> {user_id: ws}

    def register(self, conversation_id: str, user_id: str, ws: WebSocket) -> None:
        self._sockets.setdefault(conversation_id, {})[user_id] = ws

    def unregister(self, conversation_id: str, user_id: str) -> None:
        self._sockets.get(conversation_id, {}).pop(user_id, None)

    async def broadcast(self, conversation_id: str, payload: dict, exclude_user_id: str | None = None) -> None:
        for user_id, ws in list(self._sockets.get(conversation_id, {}).items()):
            if user_id == exclude_user_id:
                continue
            try:
                await ws.send_text(json.dumps(payload))
            except Exception:
                self.unregister(conversation_id, user_id)


registry = ConnectionRegistry()


async def chat_websocket_endpoint(
    websocket: WebSocket,
    conversation_id: str,
    token: str,
    chat_manager: ChatManager,
    last_received_message_id: str | None = None,
) -> None:
    """
    Client connects to `/ws/conversations/{conversation_id}?token=...` and
    optionally `&last_received_message_id=...` to backfill on reconnect.
    """
    p1_client = get_p1_client()
    try:
        identity = await p1_client.verify_token(token)
    except SessionEngineError:
        await websocket.close(code=4401)
        return

    await websocket.accept()
    registry.register(conversation_id, identity.user_id, websocket)

    # Backfill: never rely on the socket alone for consistency.
    missed = chat_manager.get_messages_since(
        conversation_id=conversation_id, last_received_message_id=last_received_message_id
    )
    if missed:
        await websocket.send_text(json.dumps({"type": "BACKFILL", "messages": [m.to_public_dict() for m in missed]}))

    try:
        while True:
            raw = await websocket.receive_text()
            data = json.loads(raw)
            if data.get("type") == "SEND_MESSAGE":
                message = await chat_manager.send_message(
                    conversation_id=conversation_id, sender_id=identity.user_id, body=data.get("body", "")
                )
                await registry.broadcast(
                    conversation_id, {"type": "NEW_MESSAGE", "message": message.to_public_dict()}
                )
            elif data.get("type") == "READ":
                chat_manager.mark_read(
                    conversation_id=conversation_id,
                    user_id=identity.user_id,
                    up_to_message_id=data.get("upToMessageId", ""),
                )
                await registry.broadcast(
                    conversation_id,
                    {"type": "READ_RECEIPT", "userId": identity.user_id, "upToMessageId": data.get("upToMessageId")},
                    exclude_user_id=identity.user_id,
                )
    except WebSocketDisconnect:
        registry.unregister(conversation_id, identity.user_id)
