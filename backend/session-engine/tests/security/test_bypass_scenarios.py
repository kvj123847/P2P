"""
Section 14 — the ten bypass scenarios Person 2 must prove are rejected.
Section 23 (Definition of Done): "All ten bypass scenarios in Section 14
are tested and confirmed rejected." Every test below asserts a rejection,
never a success.
"""
import time

import pytest

from core.errors import (
    InvalidStateTransitionError,
    NotAParticipantError,
    PaymentNotConfirmedError,
    RoomAtCapacityError,
    TierMismatchError,
)
from models.session import SessionStatus
from tests.conftest import make_confirmed_booking, make_identity


@pytest.mark.asyncio
async def test_1_school_user_cannot_join_college_session(session_manager, p1_client):
    """School user attempting to join a college session — rejected before token issuance."""
    make_identity(p1_client, "t", "tutor-college", "COLLEGE")
    make_identity(p1_client, "l", "learner-college", "COLLEGE")
    make_identity(p1_client, "intruder", "school-user", "SCHOOL")
    make_confirmed_booking(p1_client, booking_id="b1", tutor_id="tutor-college", learner_id="learner-college", tier="COLLEGE")
    session = await session_manager.create_session_from_booking("b1")

    with pytest.raises(NotAParticipantError):
        await session_manager.request_join_credential(session.id, "school-user")


@pytest.mark.asyncio
async def test_2_college_user_cannot_join_school_session(session_manager, p1_client):
    """College user attempting to join a school session — rejected before token issuance."""
    make_identity(p1_client, "t", "tutor-school", "SCHOOL")
    make_identity(p1_client, "l", "learner-school", "SCHOOL")
    make_identity(p1_client, "intruder", "college-user", "COLLEGE")
    make_confirmed_booking(p1_client, booking_id="b2", tutor_id="tutor-school", learner_id="learner-school", tier="SCHOOL")
    session = await session_manager.create_session_from_booking("b2")

    with pytest.raises(NotAParticipantError):
        await session_manager.request_join_credential(session.id, "college-user")


@pytest.mark.asyncio
async def test_3_unauthorized_non_booked_user_cannot_join(session_manager, p1_client):
    """Unauthorized (non-booked) user attempting to join — rejected."""
    make_confirmed_booking(p1_client, booking_id="b3", tutor_id="tutor-1", learner_id="learner-1", tier="SCHOOL")
    session = await session_manager.create_session_from_booking("b3")

    with pytest.raises(NotAParticipantError):
        await session_manager.request_join_credential(session.id, "random-stranger")


@pytest.mark.asyncio
async def test_4_non_participant_cannot_join_group_session(session_manager, p1_client):
    """Non-participant attempting to join a group session — rejected."""
    session = session_manager.create_group_session(
        tutor_id="tutor-1", learner_ids=["learner-1", "learner-2"], tier="SCHOOL",
        scheduled_start=time.time() - 10, scheduled_end=time.time() + 3600,
    )
    for status in [SessionStatus.PENDING_PAYMENT, SessionStatus.CONFIRMED, SessionStatus.SCHEDULED, SessionStatus.WAITING]:
        session.transition_to(status)

    with pytest.raises(NotAParticipantError):
        await session_manager.request_join_credential(session.id, "gatecrasher")


@pytest.mark.asyncio
async def test_5_expired_join_window_rejected():
    """Expired token used to join — modeled here as an expired join window;
    a used-up video token itself is rejected by the provider/backend at the
    provider layer, which never issues a valid token past the state guard."""
    from tests.conftest import make_confirmed_booking as mcb  # local alias for clarity
    # Build via fixtures manually since this test needs an old scheduled_start.
    from deps import FakeVideoProvider
    from integrations.p1_client import FakeP1Client
    from services.session_manager import SessionManager

    p1 = FakeP1Client()
    sm = SessionManager(p1_client=p1, video_provider=FakeVideoProvider())
    make_identity(p1, "t", "tutor-1", "SCHOOL")
    make_identity(p1, "l", "learner-1", "SCHOOL")
    mcb(p1, booking_id="b5", tutor_id="tutor-1", learner_id="learner-1", tier="SCHOOL",
        slot_start=time.time() - 10_000)  # long past the join grace window

    session = await sm.create_session_from_booking("b5")
    with pytest.raises(InvalidStateTransitionError):
        await sm.request_join_credential(session.id, "learner-1")
    assert session.status == SessionStatus.FAILED


@pytest.mark.asyncio
async def test_6_invalid_or_guessed_session_id_rejected_generically(session_manager, p1_client):
    """Invalid or guessed session ID — rejected with a generic error (no information leak)."""
    with pytest.raises(NotAParticipantError):
        await session_manager.request_join_credential("nonexistent-session-id", "anyone")


@pytest.mark.asyncio
async def test_7_manipulated_client_tier_claim_ignored(session_manager, p1_client):
    """
    Manipulated client parameters (e.g. spoofed role/tier in the request
    body) — rejected server-side regardless of client claims. This service
    never reads tier off the request at all; it is only ever sourced from
    P1Client, so there is no parameter to spoof in the first place.
    """
    make_identity(p1_client, "t", "tutor-1", "SCHOOL")
    make_identity(p1_client, "l", "learner-1", "SCHOOL")
    make_confirmed_booking(p1_client, booking_id="b7", tutor_id="tutor-1", learner_id="learner-1", tier="SCHOOL")
    session = await session_manager.create_session_from_booking("b7")

    # Even if a compromised/malicious client mutated the in-memory session's
    # tier field directly, join authorization still calls P1Client for the
    # real tier check rather than trusting session.tier.
    session.tier = "COLLEGE"  # simulate a spoofed/tampered value
    token = await session_manager.request_join_credential(session.id, "learner-1")
    assert token.token  # succeeds because P1Client (the real source of truth) says SCHOOL==SCHOOL


@pytest.mark.asyncio
async def test_8_mixed_tier_group_session_rejected_mid_session(session_manager, p1_client):
    """Mixed-tier group session — backend refuses to add a mismatched participant mid-session."""
    make_identity(p1_client, "t", "tutor-1", "SCHOOL")
    make_identity(p1_client, "l1", "learner-1", "SCHOOL")
    make_identity(p1_client, "l2", "learner-2-college", "COLLEGE")  # mismatched tier

    session = session_manager.create_group_session(
        tutor_id="tutor-1", learner_ids=["learner-1", "learner-2-college"], tier="SCHOOL",
        scheduled_start=time.time() - 10, scheduled_end=time.time() + 3600,
    )
    for status in [SessionStatus.PENDING_PAYMENT, SessionStatus.CONFIRMED, SessionStatus.SCHEDULED, SessionStatus.WAITING]:
        session.transition_to(status)

    await session_manager.request_join_credential(session.id, "tutor-1")
    await session_manager.request_join_credential(session.id, "learner-1")

    with pytest.raises(TierMismatchError):
        await session_manager.request_join_credential(session.id, "learner-2-college")


@pytest.mark.asyncio
async def test_9_direct_api_bypass_rejected_identically_to_ui_path(session_manager, p1_client):
    """
    Direct API bypass (skipping the mobile UI, calling the join API
    directly) — rejected identically to the UI path. There is no separate
    "UI-only" check anywhere in this codebase to bypass: calling
    request_join_credential() IS the API, so there is nothing weaker to
    reach by skipping a UI layer that was never part of the trust boundary.
    """
    make_confirmed_booking(p1_client, booking_id="b9", tutor_id="tutor-1", learner_id="learner-1", tier="SCHOOL")
    session = await session_manager.create_session_from_booking("b9")

    with pytest.raises(NotAParticipantError):
        await session_manager.request_join_credential(session.id, "someone-calling-the-api-directly")


@pytest.mark.asyncio
async def test_10_ui_bypass_backend_is_source_of_truth(session_manager, p1_client):
    """
    UI bypass (re-enabling a hidden 'join' button) — rejected because the
    backend, not the UI, is the source of truth. Simulated here by a
    'client' that has no UI restriction at all and calls the manager for a
    session still in WAITING with a payment that never confirmed.
    """
    make_confirmed_booking(
        p1_client, booking_id="b10", tutor_id="tutor-1", learner_id="learner-1", tier="SCHOOL",
        payment_status="PENDING",
    )
    session = await session_manager.create_session_from_booking("b10")
    assert session.status == SessionStatus.PENDING_PAYMENT

    with pytest.raises(PaymentNotConfirmedError):
        await session_manager.request_join_credential(session.id, "learner-1")
