"""
Section 16 network test matrix, the parts that are meaningfully testable at
the ConnectionManager/SessionManager level without a real device or SDK
(Wi-Fi<->mobile data, packet loss, latency, camera/mic permission failures,
etc. require the Phase 1 POC's real devices — see
docs/architecture/VIDEO_PROVIDER_DECISION_MEMO.md
and run those manually per Section 5's "Test it" instructions).
"""
import time

import pytest

from models.participant import ConnectionState, ParticipantRole
from services.connection_manager import ConnectionManager
from services.participant_manager import ParticipantManager


def test_reconnect_within_grace_window_stays_live():
    pm = ParticipantManager()
    cm = ConnectionManager(reconnect_grace_seconds=30)
    pm.add_expected_participant("s1", "learner-1", ParticipantRole.LEARNER)
    p = pm.join("s1", "learner-1", max_capacity=5)

    cm.on_network_drop(p)
    assert p.connection_state == ConnectionState.RECONNECTING
    cm.on_network_restored(p)
    assert p.connection_state == ConnectionState.CONNECTED
    # Session itself never needed to change state for a transient drop —
    # LIVE the whole time from the SessionManager's point of view.


def test_reconnect_beyond_grace_window_marks_disconnected_not_failed():
    """
    Section 4: "session stays LIVE for a bounded window, then marks the
    participant DISCONNECTED if it doesn't recover" — the SESSION does not
    fail just because one participant's network failed permanently.
    """
    pm = ParticipantManager()
    cm = ConnectionManager(reconnect_grace_seconds=5)
    pm.add_expected_participant("s1", "learner-1", ParticipantRole.LEARNER)
    p = pm.join("s1", "learner-1", max_capacity=5)

    cm.on_network_drop(p)
    now = time.time() + 100
    disconnected = cm.sweep_expired_reconnects([p], now=now)
    assert disconnected == [p]
    assert p.connection_state == ConnectionState.DISCONNECTED


def test_repeated_join_leave_churn_does_not_corrupt_roster():
    pm = ParticipantManager()
    pm.add_expected_participant("s1", "learner-1", ParticipantRole.LEARNER)
    for _ in range(20):
        pm.join("s1", "learner-1", max_capacity=5)
        pm.leave("s1", "learner-1")
    assert pm.connected_count("s1") == 0
    assert len(pm.roster("s1")) == 1  # still one logical participant, not 20 ghosts


def test_join_leave_join_again_re_admits_participant():
    pm = ParticipantManager()
    pm.add_expected_participant("s1", "learner-1", ParticipantRole.LEARNER)
    pm.join("s1", "learner-1", max_capacity=1)
    pm.leave("s1", "learner-1")
    p = pm.join("s1", "learner-1", max_capacity=1)  # capacity freed up after leave
    assert p.connection_state == ConnectionState.CONNECTED
