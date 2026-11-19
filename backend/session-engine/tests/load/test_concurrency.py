"""
Section 16 load category: "Concurrent 1-to-1 and group sessions, join/leave
churn, WebSocket connection count, session-API throughput." A real load test
needs a running server and a tool like locust/k6 against the deployed
session-engine; this is a lightweight in-process smoke test that at least
proves the managers behave correctly under many concurrent sessions, which
is a prerequisite for any real load test being meaningful.
"""
import asyncio
import time

import pytest

from tests.conftest import make_confirmed_booking, make_identity


@pytest.mark.asyncio
async def test_many_concurrent_one_to_one_sessions_stay_isolated(session_manager, p1_client):
    n = 50
    for i in range(n):
        make_identity(p1_client, f"t{i}", f"tutor-{i}", "SCHOOL")
        make_identity(p1_client, f"l{i}", f"learner-{i}", "SCHOOL")
        make_confirmed_booking(
            p1_client, booking_id=f"booking-{i}", tutor_id=f"tutor-{i}", learner_id=f"learner-{i}", tier="SCHOOL"
        )

    sessions = await asyncio.gather(
        *[session_manager.create_session_from_booking(f"booking-{i}") for i in range(n)]
    )
    assert len({s.id for s in sessions}) == n  # every session is distinct

    tokens = await asyncio.gather(
        *[session_manager.request_join_credential(s.id, f"tutor-{i}") for i, s in enumerate(sessions)]
    )
    # Every room/channel is unique — no cross-session leakage under concurrency.
    assert len({t.channel_name for t in tokens}) == n


@pytest.mark.asyncio
async def test_join_leave_churn_across_many_sessions_no_leak(session_manager, p1_client):
    make_identity(p1_client, "t", "tutor-1", "SCHOOL")
    make_identity(p1_client, "l", "learner-1", "SCHOOL")
    make_confirmed_booking(p1_client, booking_id="churn-booking", tutor_id="tutor-1", learner_id="learner-1", tier="SCHOOL")
    session = await session_manager.create_session_from_booking("churn-booking")

    # Learner stays connected throughout so the session doesn't auto-complete
    # while the tutor churns join/leave (a lone remaining participant keeps
    # a 1-to-1 session LIVE, per the SessionManager's leave() logic).
    await session_manager.request_join_credential(session.id, "learner-1")

    for _ in range(200):
        await session_manager.request_join_credential(session.id, "tutor-1")
        session_manager.leave(session.id, "tutor-1")

    # Roster still has exactly the two expected participants, not 400 ghosts.
    assert len(session_manager.participant_manager.roster(session.id)) == 2
