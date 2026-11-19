import time

import pytest

from core.errors import RoomAtCapacityError, ValidationError
from models.participant import ConnectionState, ParticipantRole
from services.connection_manager import ConnectionManager
from services.participant_manager import ParticipantManager


def test_join_requires_expected_participant():
    pm = ParticipantManager()
    with pytest.raises(ValidationError):
        pm.join("s1", "unexpected-user", max_capacity=2)


def test_capacity_enforced():
    pm = ParticipantManager()
    pm.add_expected_participant("s1", "tutor", ParticipantRole.TUTOR)
    pm.add_expected_participant("s1", "learner1", ParticipantRole.LEARNER)
    pm.add_expected_participant("s1", "learner2", ParticipantRole.LEARNER)

    pm.join("s1", "tutor", max_capacity=2)
    pm.join("s1", "learner1", max_capacity=2)
    with pytest.raises(RoomAtCapacityError):
        pm.join("s1", "learner2", max_capacity=2)


def test_host_controls_require_host_role():
    pm = ParticipantManager()
    pm.add_expected_participant("s1", "tutor", ParticipantRole.TUTOR)
    pm.add_expected_participant("s1", "learner1", ParticipantRole.LEARNER)
    pm.join("s1", "tutor", max_capacity=5)
    pm.join("s1", "learner1", max_capacity=5)

    with pytest.raises(ValidationError):
        pm.host_mute_participant("s1", "learner1", "tutor")  # learner is not host

    pm.host_mute_participant("s1", "tutor", "learner1")
    assert pm.get("s1", "learner1").audio_on is False


def test_connection_manager_reconnect_grace_window():
    cm = ConnectionManager(reconnect_grace_seconds=10)
    pm = ParticipantManager()
    pm.add_expected_participant("s1", "learner1", ParticipantRole.LEARNER)
    p = pm.join("s1", "learner1", max_capacity=5)

    cm.on_network_drop(p)
    assert p.connection_state == ConnectionState.RECONNECTING

    disconnected = cm.sweep_expired_reconnects([p], now=time.time() + 5)
    assert disconnected == []  # still within grace window

    disconnected = cm.sweep_expired_reconnects([p], now=time.time() + 20)
    assert disconnected == [p]
    assert p.connection_state == ConnectionState.DISCONNECTED


def test_connection_manager_reconnect_recovers():
    cm = ConnectionManager(reconnect_grace_seconds=10)
    pm = ParticipantManager()
    pm.add_expected_participant("s1", "learner1", ParticipantRole.LEARNER)
    p = pm.join("s1", "learner1", max_capacity=5)

    cm.on_network_drop(p)
    cm.on_network_restored(p)
    assert p.connection_state == ConnectionState.CONNECTED
