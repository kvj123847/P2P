"""
In-memory mock Person 1 identities and bookings for local API testing.

Enable with environment variable DEV_MOCK_DATA=true when starting uvicorn.
"""
from __future__ import annotations

import time
from dataclasses import dataclass

from integrations.p1_client import BookingRecord, FakeP1Client, Identity, get_p1_client

# Bearer tokens (use in Authorization: Bearer <token>)
MOCK_TOKEN_COLLEGE_TUTOR = "mock-token-alice-tutor"
MOCK_TOKEN_COLLEGE_LEARNER = "mock-token-bob-learner"
MOCK_TOKEN_SCHOOL_TUTOR = "mock-token-carol-school-tutor"

# Booking ids for POST /sessions
MOCK_BOOKING_COLLEGE_CONFIRMED = "mock-booking-college-001"
MOCK_BOOKING_PAYMENT_PENDING = "mock-booking-college-pending-002"

MOCK_USER_ALICE = "user-alice-tutor"
MOCK_USER_BOB = "user-bob-learner"
MOCK_USER_CAROL = "user-carol-school-tutor"


@dataclass(frozen=True)
class MockDataSummary:
    base_url_hint: str = "http://127.0.0.1:8001"
    college_booking_id: str = MOCK_BOOKING_COLLEGE_CONFIRMED
    pending_booking_id: str = MOCK_BOOKING_PAYMENT_PENDING
    college_tutor_token: str = MOCK_TOKEN_COLLEGE_TUTOR
    college_learner_token: str = MOCK_TOKEN_COLLEGE_LEARNER
    school_tutor_token: str = MOCK_TOKEN_SCHOOL_TUTOR


def seed_mock_p1_data() -> MockDataSummary:
    client = get_p1_client()
    if not isinstance(client, FakeP1Client):
        return MockDataSummary()

    now = time.time()

    client.register_identity(
        MOCK_TOKEN_COLLEGE_TUTOR,
        Identity(user_id=MOCK_USER_ALICE, tier="COLLEGE", roles=["tutor"]),
    )
    client.register_identity(
        MOCK_TOKEN_COLLEGE_LEARNER,
        Identity(user_id=MOCK_USER_BOB, tier="COLLEGE", roles=["learner"]),
    )
    client.register_identity(
        MOCK_TOKEN_SCHOOL_TUTOR,
        Identity(user_id=MOCK_USER_CAROL, tier="SCHOOL", roles=["tutor"]),
    )

    client.register_booking(
        BookingRecord(
            booking_id=MOCK_BOOKING_COLLEGE_CONFIRMED,
            tutor_id=MOCK_USER_ALICE,
            learner_id=MOCK_USER_BOB,
            tier="COLLEGE",
            payment_status="CONFIRMED",
            slot_start=now - 60,
            slot_end=now + 3600,
        )
    )
    client.register_booking(
        BookingRecord(
            booking_id=MOCK_BOOKING_PAYMENT_PENDING,
            tutor_id=MOCK_USER_ALICE,
            learner_id=MOCK_USER_BOB,
            tier="COLLEGE",
            payment_status="PENDING",
            slot_start=now - 60,
            slot_end=now + 3600,
        )
    )

    for booking_id in (MOCK_BOOKING_COLLEGE_CONFIRMED, MOCK_BOOKING_PAYMENT_PENDING):
        client.register_participant(booking_id, MOCK_USER_ALICE)
        client.register_participant(booking_id, MOCK_USER_BOB)

    return MockDataSummary()
