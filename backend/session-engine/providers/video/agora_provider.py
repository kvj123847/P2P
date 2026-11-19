"""Agora RTC token provider.

Only this module imports the Agora SDK. Authorization is completed by
SessionManager and Person 1 before this provider is called.
"""
from __future__ import annotations

import time
import zlib

from core.config import settings
from core.errors import ProviderUnavailableError
from providers.video.video_provider import VideoProvider, VideoToken

try:
    from agora_token_builder.RtcTokenBuilder import Role_Publisher, RtcTokenBuilder
except ImportError as exc:  # pragma: no cover - exercised by deployment checks
    Role_Publisher = None
    RtcTokenBuilder = None
    _IMPORT_ERROR = exc
else:
    _IMPORT_ERROR = None


class AgoraProvider(VideoProvider):
    def __init__(self, app_id: str | None = None, app_certificate: str | None = None) -> None:
        if _IMPORT_ERROR is not None:
            raise ProviderUnavailableError(
                "Install agora-token-builder before starting the Agora provider"
            ) from _IMPORT_ERROR
        self.app_id = app_id or settings.agora_app_id
        self.app_certificate = app_certificate or settings.agora_app_certificate
        if not self.app_id or not self.app_certificate:
            raise ProviderUnavailableError(
                "AGORA_APP_ID and AGORA_APP_CERTIFICATE are required"
            )

    def create_room(self, session_id: str) -> str:
        return f"session-{session_id}"

    @staticmethod
    def numeric_uid(user_id: str) -> int:
        """Map an internal ID to a stable, valid non-zero Agora RTC UID."""
        return (zlib.crc32(user_id.encode("utf-8")) & 0x7FFFFFFF) or 1

    def generate_token(self, *, channel_name: str, user_id: str, ttl_seconds: int) -> VideoToken:
        if ttl_seconds <= 0:
            raise ProviderUnavailableError("Video token TTL must be positive")
        expires_at = int(time.time()) + ttl_seconds
        uid = self.numeric_uid(user_id)
        token = RtcTokenBuilder.buildTokenWithUid(
            self.app_id,
            self.app_certificate,
            channel_name,
            uid,
            Role_Publisher,
            expires_at,
        )
        return VideoToken(
            token=token,
            channel_name=channel_name,
            uid=str(uid),
            expires_at=float(expires_at),
        )

    def revoke_room(self, channel_name: str) -> None:
        return None

    def estimated_cost_per_minute(self, participant_count: int) -> float:
        return 0.0
