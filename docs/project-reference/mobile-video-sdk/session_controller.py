"""
SessionController — the thin façade Person 3 talks to (Section 20):

    joinSession(sessionId)
    leaveSession()
    toggleCamera()
    toggleMicrophone()

"Person 3 never touches the video SDK directly. They call your façade and
subscribe to your events." This client wraps HTTP calls to the session-engine
API (Section 19 contract) and emits typed state via EventEmitter so a mobile
screen can bind purely to `state`, exactly like the real RN/Flutter package
would.

Note: this is the reference/demo client used for integration testing and to
give Person 3 an exact contract to port to TypeScript/Dart. The
production mobile app itself is Person 3's ownership (React Native/Flutter);
this Python module is not meant to ship inside the mobile binary.
"""
from __future__ import annotations

import httpx

from .events import ConnectionState, EventEmitter, ParticipantState, SdkState, SessionState


class SessionController:
    def __init__(self, base_url: str, bearer_token: str) -> None:
        self._base_url = base_url.rstrip("/")
        self._token = bearer_token
        self._client = httpx.Client(base_url=self._base_url, headers={"Authorization": f"Bearer {bearer_token}"})
        self.events = EventEmitter()
        self.state = SdkState()
        self._current_session_id: str | None = None

    # --- public façade methods (Section 20) ---
    def join_session(self, session_id: str) -> None:
        self._current_session_id = session_id
        try:
            resp = self._client.post(f"/sessions/{session_id}/join")
            resp.raise_for_status()
            credential = resp.json()
            self.state.connection_state = ConnectionState.CONNECTED
            self._refresh_session_state(session_id)
            self._refresh_participants(session_id)
            self.events.emit("connectionState", self.state.connection_state)
            self.events.emit("credentialIssued", credential)
        except httpx.HTTPStatusError as exc:
            self.state.connection_state = ConnectionState.FAILED
            self.state.error_state = exc.response.text
            self.events.emit("errorState", self.state.error_state)

    def leave_session(self) -> None:
        if not self._current_session_id:
            return
        try:
            self._client.post(f"/sessions/{self._current_session_id}/leave")
        finally:
            self.state.connection_state = ConnectionState.NOT_JOINED
            self.events.emit("connectionState", self.state.connection_state)
            self._current_session_id = None

    def toggle_camera(self) -> None:
        self.state.local_video_on = not self.state.local_video_on
        self.events.emit("localVideoState", self.state.local_video_on)

    def toggle_microphone(self) -> None:
        self.state.local_audio_on = not self.state.local_audio_on
        self.events.emit("microphoneState", self.state.local_audio_on)

    # --- internal helpers ---
    def _refresh_session_state(self, session_id: str) -> None:
        resp = self._client.get(f"/sessions/{session_id}")
        resp.raise_for_status()
        data = resp.json()
        self.state.session_state = SessionState(data["status"])
        self.events.emit("sessionState", self.state.session_state)

    def _refresh_participants(self, session_id: str) -> None:
        resp = self._client.get(f"/sessions/{session_id}/participants")
        resp.raise_for_status()
        self.state.participants = [ParticipantState(**p) for p in resp.json()]
        self.events.emit("participants", self.state.participants)

    def close(self) -> None:
        self._client.close()
