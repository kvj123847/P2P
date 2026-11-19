"""
ConnectionManager (Phase 4): explicit per-participant connection states —
CONNECTED, RECONNECTING, DISCONNECTED, FAILED — decoupled from session
status itself, so a network blip for one participant never corrupts the
session state machine (Section 4: "Network fails mid-session -> participant
enters RECONNECTING ... session stays LIVE for a bounded window").
"""
from __future__ import annotations

import time

from core.config import settings
from models.participant import ConnectionState, Participant


class ConnectionManager:
    def __init__(self, reconnect_grace_seconds: int | None = None) -> None:
        self.reconnect_grace_seconds = reconnect_grace_seconds or settings.reconnect_grace_seconds

    def on_network_drop(self, participant: Participant) -> None:
        if participant.connection_state == ConnectionState.CONNECTED:
            participant.mark_reconnecting()

    def on_network_restored(self, participant: Participant) -> None:
        if participant.connection_state in (ConnectionState.RECONNECTING, ConnectionState.DISCONNECTED):
            participant.mark_reconnected()

    def sweep_expired_reconnects(self, participants: list[Participant], now: float | None = None) -> list[Participant]:
        """
        Call periodically (or on-demand before reading roster state) to move
        anyone who has been RECONNECTING past the grace window into
        DISCONNECTED. Returns the list of participants that were just
        transitioned, so callers (e.g. NotificationManager) can react.
        """
        now = now if now is not None else time.time()
        newly_disconnected = []
        for p in participants:
            if (
                p.connection_state == ConnectionState.RECONNECTING
                and p.disconnected_since is not None
                and now - p.disconnected_since > self.reconnect_grace_seconds
            ):
                p.mark_left()
                newly_disconnected.append(p)
        return newly_disconnected

    def is_healthy(self, participant: Participant) -> bool:
        return participant.connection_state == ConnectionState.CONNECTED
