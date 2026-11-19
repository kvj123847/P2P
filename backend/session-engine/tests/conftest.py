from __future__ import annotations

import sys
import time
from pathlib import Path

import pytest

# Allow `import core`, `import services`, etc. when running pytest from repo root.
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from deps import FakeVideoProvider
from integrations.p1_client import BookingRecord, FakeP1Client, Identity
from services.chat_manager import ChatManager
from services.notification_manager import NotificationManager
from services.session_manager import SessionManager


@pytest.fixture
def p1_client() -> FakeP1Client:
    return FakeP1Client()


@pytest.fixture
def video_provider() -> FakeVideoProvider:
    return FakeVideoProvider()


@pytest.fixture
def notifications() -> NotificationManager:
    return NotificationManager()


@pytest.fixture
def session_manager(p1_client, video_provider, notifications) -> SessionManager:
    return SessionManager(p1_client=p1_client, video_provider=video_provider, notification_manager=notifications)


@pytest.fixture
def chat_manager(p1_client) -> ChatManager:
    return ChatManager(p1_client=p1_client, page_size=30)


def make_identity(p1_client: FakeP1Client, token: str, user_id: str, tier: str, roles=None) -> Identity:
    identity = Identity(user_id=user_id, tier=tier, roles=roles or ["learner"])
    p1_client.register_identity(token, identity)
    return identity


def make_confirmed_booking(
    p1_client: FakeP1Client,
    *,
    booking_id: str,
    tutor_id: str,
    learner_id: str,
    tier: str,
    payment_status: str = "CONFIRMED",
    slot_start: float | None = None,
) -> BookingRecord:
    now = time.time()
    booking = BookingRecord(
        booking_id=booking_id,
        tutor_id=tutor_id,
        learner_id=learner_id,
        tier=tier,
        payment_status=payment_status,
        slot_start=slot_start if slot_start is not None else now - 10,
        slot_end=now + 3000,
    )
    p1_client.register_booking(booking)
    p1_client.register_participant(booking_id, tutor_id)
    p1_client.register_participant(booking_id, learner_id)
    return booking
