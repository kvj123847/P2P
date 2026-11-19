"""
VideoManager (Phase 2-5): the only manager allowed to talk to
VideoProvider/AgoraProvider. Orchestrates room creation, token issuance, and
join/leave/mute/camera actions, but NEVER decides who is allowed to join —
that decision always comes from SessionManager's secure join flow (Section
14), which itself defers to P1Client for identity/tier/payment checks.
"""
from __future__ import annotations

from core.config import settings
from providers.video.video_provider import VideoProvider, VideoToken
from services.room_manager import RoomManager


class VideoManager:
    def __init__(self, video_provider: VideoProvider, room_manager: RoomManager | None = None) -> None:
        self.video_provider = video_provider
        self.room_manager = room_manager or RoomManager(video_provider)

    def issue_join_credential(self, session_id: str, user_id: str) -> VideoToken:
        """
        Only ever called AFTER SessionManager has confirmed, via P1Client:
        authentication, session validity, participant membership, payment
        status, and tier match. This method itself performs zero
        authorization — see Section 14's secure join flow diagram.
        """
        channel_name = self.room_manager.get_or_create_room(session_id)
        return self.video_provider.generate_token(
            channel_name=channel_name,
            user_id=user_id,
            ttl_seconds=settings.video_token_ttl_seconds,
        )

    def refresh_credential_if_needed(self, session_id: str, user_id: str, token: VideoToken, now: float) -> VideoToken:
        """
        Section 4: "Video token expires -> VideoManager detects the
        provider's expiry callback and silently requests a refreshed token
        from the backend before it lapses." Here we model that as: caller
        polls with the current token and gets a fresh one issued once it's
        within 60s of expiry.
        """
        if token.expires_at - now > 60:
            return token
        return self.issue_join_credential(session_id, user_id)

    def teardown(self, session_id: str) -> None:
        self.room_manager.teardown_room(session_id)
