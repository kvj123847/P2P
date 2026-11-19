"""
Composition root: builds the singleton managers the whole app shares, and
exposes them as FastAPI dependencies. Kept separate from main.py so tests
can import and override individual pieces (e.g. swap FakeP1Client for a
scripted one) without booting the ASGI app.
"""
from __future__ import annotations

from core.config import settings
from integrations.p1_client import get_p1_client
from providers.video.agora_provider import AgoraProvider
from providers.video.video_provider import VideoProvider
from services.chat_manager import ChatManager
from services.notification_manager import NotificationManager
from services.session_manager import SessionManager


class FakeVideoProvider(VideoProvider):
    """Zero-config provider used until real Agora credentials exist, so the
    app boots and is fully testable without any external service."""

    def create_room(self, session_id: str) -> str:
        return f"room-{session_id}"

    def generate_token(self, *, channel_name: str, user_id: str, ttl_seconds: int):
        from providers.video.video_provider import VideoToken
        import time

        return VideoToken(token=f"fake-token-{channel_name}-{user_id}", channel_name=channel_name,
                           uid=user_id, expires_at=time.time() + ttl_seconds)

    def revoke_room(self, channel_name: str) -> None:
        return None

    def estimated_cost_per_minute(self, participant_count: int) -> float:
        return 0.0


def _build_video_provider() -> VideoProvider:
    if settings.video_provider_name == "agora":
        return AgoraProvider()
    raise RuntimeError(f"Unsupported video provider: {settings.video_provider_name}")


_notification_manager = NotificationManager()
_session_manager: SessionManager | None = None
_chat_manager: ChatManager | None = None


def get_session_manager() -> SessionManager:
    global _session_manager
    if _session_manager is None:
        _session_manager = SessionManager(
            p1_client=get_p1_client(),
            video_provider=_build_video_provider(),
            notification_manager=_notification_manager,
        )
    return _session_manager


def get_chat_manager() -> ChatManager:
    global _chat_manager
    if _chat_manager is None:
        _chat_manager = ChatManager(
            p1_client=get_p1_client(),
            page_size=settings.chat_page_size,
        )
    return _chat_manager


def get_notification_manager() -> NotificationManager:
    return _notification_manager
