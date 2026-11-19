"""
RoomManager (Phase 4): owns room existence/teardown, decoupled from
VideoManager's join/leave orchestration and from ParticipantManager's
roster tracking, so each has one job.
"""
from __future__ import annotations

from providers.video.video_provider import VideoProvider


class RoomManager:
    def __init__(self, video_provider: VideoProvider) -> None:
        self.video_provider = video_provider
        self._rooms: dict[str, str] = {}  # session_id -> channel_name

    def get_or_create_room(self, session_id: str) -> str:
        if session_id not in self._rooms:
            self._rooms[session_id] = self.video_provider.create_room(session_id)
        return self._rooms[session_id]

    def teardown_room(self, session_id: str) -> None:
        channel_name = self._rooms.pop(session_id, None)
        if channel_name:
            self.video_provider.revoke_room(channel_name)

    def room_exists(self, session_id: str) -> bool:
        return session_id in self._rooms
