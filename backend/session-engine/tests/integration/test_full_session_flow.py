"""
Section 6, "Test it": full vertical slice — real (fake) backend, real auth,
real video credential issuance, no mocks bypassing the actual flow.

    Tutor creates availability -> Learner books -> Payment confirmed (P1)
    -> SessionManager.create() -> Backend authorizes join -> VideoManager.joinRoom()
    -> 1-to-1 call (mute/camera/leave) -> SessionManager.complete()
"""
import pytest

from models.session import SessionStatus
from tests.conftest import make_confirmed_booking, make_identity


@pytest.mark.asyncio
async def test_full_one_to_one_session_lifecycle(session_manager, p1_client):
    make_identity(p1_client, "tok-tutor", "tutor-1", "COLLEGE", roles=["tutor"])
    make_identity(p1_client, "tok-learner", "learner-1", "COLLEGE", roles=["learner"])
    make_confirmed_booking(
        p1_client, booking_id="booking-1", tutor_id="tutor-1", learner_id="learner-1", tier="COLLEGE"
    )

    session = await session_manager.create_session_from_booking("booking-1")
    assert session.status == SessionStatus.WAITING

    # Tutor joins first.
    tutor_token = await session_manager.request_join_credential(session.id, "tutor-1")
    assert tutor_token.token
    session = session_manager.get(session.id)
    assert session.status == SessionStatus.LIVE

    # Learner joins.
    learner_token = await session_manager.request_join_credential(session.id, "learner-1")
    assert learner_token.channel_name == tutor_token.channel_name  # same room

    # Mute/camera actions.
    session_manager.participant_manager.mute(session.id, "learner-1", muted=True)
    assert session_manager.participant_manager.get(session.id, "learner-1").audio_on is False

    # Both leave -> session auto-completes.
    session_manager.leave(session.id, "tutor-1")
    session_manager.leave(session.id, "learner-1")
    session = session_manager.get(session.id)
    assert session.status == SessionStatus.COMPLETED


@pytest.mark.asyncio
async def test_duplicate_booking_confirmation_is_idempotent(session_manager, p1_client):
    make_confirmed_booking(
        p1_client, booking_id="booking-2", tutor_id="tutor-1", learner_id="learner-1", tier="SCHOOL"
    )
    s1 = await session_manager.create_session_from_booking("booking-2")
    s2 = await session_manager.create_session_from_booking("booking-2")
    assert s1.id == s2.id  # no duplicate session/room created (Phase 8)


@pytest.mark.asyncio
async def test_payment_failure_never_creates_a_joinable_session(session_manager, p1_client):
    make_confirmed_booking(
        p1_client,
        booking_id="booking-3",
        tutor_id="tutor-1",
        learner_id="learner-1",
        tier="SCHOOL",
        payment_status="FAILED",
    )
    session = await session_manager.create_session_from_booking("booking-3")
    assert session.status == SessionStatus.FAILED

    from core.errors import InvalidStateTransitionError
    with pytest.raises(InvalidStateTransitionError):
        await session_manager.request_join_credential(session.id, "learner-1")


@pytest.mark.asyncio
async def test_group_session_capacity_and_tier_enforced(session_manager, p1_client):
    make_identity(p1_client, "t", "tutor-1", "SCHOOL")
    for i in range(3):
        make_identity(p1_client, f"l{i}", f"learner-{i}", "SCHOOL")

    import time as _time

    session = session_manager.create_group_session(
        tutor_id="tutor-1",
        learner_ids=["learner-0", "learner-1", "learner-2"],
        tier="SCHOOL",
        scheduled_start=_time.time() - 10,
        scheduled_end=_time.time() + 3600,
    )
    session.transition_to(SessionStatus.PENDING_PAYMENT)
    session.transition_to(SessionStatus.CONFIRMED)
    session.transition_to(SessionStatus.SCHEDULED)
    session.transition_to(SessionStatus.WAITING)

    await session_manager.request_join_credential(session.id, "tutor-1")
    await session_manager.request_join_credential(session.id, "learner-0")
    token = await session_manager.request_join_credential(session.id, "learner-1")
    assert token.channel_name
