"""
ParticipantManager (Phase 4/5): tracks the full roster for a session — host
(tutor) + N learners, each with role/audio/video/connection state. Used by
both 1-to-1 and group sessions per Section 4's directive to build "a real
ParticipantManager" rather than treating group as "1-to-1 with more people".
"""
from __future__ import annotations

from core.errors import RoomAtCapacityError, ValidationError
from models.participant import ConnectionState, Participant, ParticipantRole


class ParticipantManager:
    def __init__(self) -> None:
        # session_id -> {user_id: Participant}
        self._rosters: dict[str, dict[str, Participant]] = {}

    def ensure_roster(self, session_id: str) -> dict[str, Participant]:
        return self._rosters.setdefault(session_id, {})

    def add_expected_participant(self, session_id: str, user_id: str, role: ParticipantRole) -> Participant:
        roster = self.ensure_roster(session_id)
        if user_id not in roster:
            roster[user_id] = Participant(session_id=session_id, user_id=user_id, role=role)
        return roster[user_id]

    def join(self, session_id: str, user_id: str, max_capacity: int) -> Participant:
        roster = self.ensure_roster(session_id)
        participant = roster.get(user_id)
        if participant is None:
            raise ValidationError(f"{user_id} is not an expected participant of session {session_id}.")

        currently_connected = sum(
            1 for p in roster.values() if p.connection_state == ConnectionState.CONNECTED
        )
        if participant.connection_state != ConnectionState.CONNECTED and currently_connected >= max_capacity:
            raise RoomAtCapacityError(f"Session {session_id} is at capacity ({max_capacity}).")

        participant.mark_joined()
        return participant

    def leave(self, session_id: str, user_id: str) -> Participant | None:
        roster = self._rosters.get(session_id, {})
        participant = roster.get(user_id)
        if participant:
            participant.mark_left()
        return participant

    def mute(self, session_id: str, user_id: str, muted: bool) -> Participant | None:
        p = self._rosters.get(session_id, {}).get(user_id)
        if p:
            p.audio_on = not muted
        return p

    def set_camera(self, session_id: str, user_id: str, on: bool) -> Participant | None:
        p = self._rosters.get(session_id, {}).get(user_id)
        if p:
            p.video_on = on
        return p

    def roster(self, session_id: str) -> list[Participant]:
        return list(self._rosters.get(session_id, {}).values())

    def connected_count(self, session_id: str) -> int:
        return sum(
            1 for p in self.roster(session_id) if p.connection_state == ConnectionState.CONNECTED
        )

    def get(self, session_id: str, user_id: str) -> Participant | None:
        return self._rosters.get(session_id, {}).get(user_id)

    # --- host controls (Section 9) ---
    def host_mute_participant(self, session_id: str, host_user_id: str, target_user_id: str) -> None:
        self._assert_is_host(session_id, host_user_id)
        target = self._rosters.get(session_id, {}).get(target_user_id)
        if target:
            target.audio_on = False

    def host_remove_participant(self, session_id: str, host_user_id: str, target_user_id: str) -> None:
        self._assert_is_host(session_id, host_user_id)
        target = self._rosters.get(session_id, {}).get(target_user_id)
        if target:
            target.mark_left()

    def _assert_is_host(self, session_id: str, user_id: str) -> None:
        p = self._rosters.get(session_id, {}).get(user_id)
        if p is None or p.role != ParticipantRole.TUTOR:
            raise ValidationError("Only the host (tutor) may perform this action.")
