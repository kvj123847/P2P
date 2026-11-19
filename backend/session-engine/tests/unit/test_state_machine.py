import pytest

from core.errors import InvalidStateTransitionError
from models.session import Session, SessionStatus


def test_legal_happy_path_transitions():
    s = Session()
    assert s.status == SessionStatus.CREATED
    s.transition_to(SessionStatus.PENDING_PAYMENT)
    s.transition_to(SessionStatus.CONFIRMED)
    s.transition_to(SessionStatus.SCHEDULED)
    s.transition_to(SessionStatus.WAITING)
    s.transition_to(SessionStatus.LIVE)
    s.transition_to(SessionStatus.COMPLETED)
    assert s.is_terminal()


@pytest.mark.parametrize(
    "from_status,to_status",
    [
        (SessionStatus.CREATED, SessionStatus.LIVE),
        (SessionStatus.CREATED, SessionStatus.COMPLETED),
        (SessionStatus.WAITING, SessionStatus.CONFIRMED),
        (SessionStatus.LIVE, SessionStatus.SCHEDULED),
        (SessionStatus.COMPLETED, SessionStatus.LIVE),
        (SessionStatus.CANCELLED, SessionStatus.WAITING),
        (SessionStatus.FAILED, SessionStatus.LIVE),
    ],
)
def test_illegal_transitions_raise(from_status, to_status):
    s = Session(status=from_status)
    with pytest.raises(InvalidStateTransitionError):
        s.transition_to(to_status)


def test_payment_failure_path():
    s = Session()
    s.transition_to(SessionStatus.PENDING_PAYMENT)
    s.transition_to(SessionStatus.FAILED, reason="Payment failed.")
    assert s.status == SessionStatus.FAILED
    assert s.fail_reason == "Payment failed."
    assert s.is_terminal()


def test_cancel_from_every_pre_live_state():
    for status in [
        SessionStatus.CREATED,
        SessionStatus.PENDING_PAYMENT,
        SessionStatus.CONFIRMED,
        SessionStatus.SCHEDULED,
        SessionStatus.WAITING,
    ]:
        s = Session(status=status)
        s.transition_to(SessionStatus.CANCELLED, reason="test")
        assert s.status == SessionStatus.CANCELLED


def test_join_window_expiry():
    s = Session(status=SessionStatus.WAITING, scheduled_start=1000.0)
    assert s.join_window_expired(grace_seconds=600, now=1000.0) is False
    assert s.join_window_expired(grace_seconds=600, now=1700.0) is True
