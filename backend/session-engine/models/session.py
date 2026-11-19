"""
Session domain model + state machine (Phase 0, Section 4).

    CREATED -> PENDING_PAYMENT -> CONFIRMED -> SCHEDULED -> WAITING -> LIVE -> COMPLETED
                                                                 \\-> CANCELLED
                                                                 \\-> FAILED

This is the single source of truth for which transitions are legal. Every
manager that changes a session's status MUST go through
`Session.transition_to()` rather than setting `.status` directly, so an
illegal transition raises instead of silently corrupting state.
"""
from __future__ import annotations

import time
import uuid
from dataclasses import dataclass, field
from enum import Enum

from core.errors import InvalidStateTransitionError


class SessionType(str, Enum):
    ONE_TO_ONE = "ONE_TO_ONE"
    GROUP = "GROUP"
    CHAT = "CHAT"


class SessionStatus(str, Enum):
    CREATED = "CREATED"
    PENDING_PAYMENT = "PENDING_PAYMENT"
    CONFIRMED = "CONFIRMED"
    SCHEDULED = "SCHEDULED"
    WAITING = "WAITING"
    LIVE = "LIVE"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"
    FAILED = "FAILED"


# The authoritative transition table from Section 4 of the roadmap.
_ALLOWED_TRANSITIONS: dict[SessionStatus, set[SessionStatus]] = {
    SessionStatus.CREATED: {SessionStatus.PENDING_PAYMENT, SessionStatus.CANCELLED},
    SessionStatus.PENDING_PAYMENT: {SessionStatus.CONFIRMED, SessionStatus.FAILED, SessionStatus.CANCELLED},
    SessionStatus.CONFIRMED: {SessionStatus.SCHEDULED, SessionStatus.CANCELLED},
    SessionStatus.SCHEDULED: {SessionStatus.WAITING, SessionStatus.CANCELLED},
    SessionStatus.WAITING: {SessionStatus.LIVE, SessionStatus.FAILED, SessionStatus.CANCELLED},
    SessionStatus.LIVE: {SessionStatus.COMPLETED, SessionStatus.FAILED},
    SessionStatus.COMPLETED: set(),
    SessionStatus.CANCELLED: set(),
    SessionStatus.FAILED: set(),
}

TERMINAL_STATES = {SessionStatus.COMPLETED, SessionStatus.CANCELLED, SessionStatus.FAILED}


@dataclass
class Session:
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    type: SessionType = SessionType.ONE_TO_ONE
    status: SessionStatus = SessionStatus.CREATED
    tutor_id: str = ""
    learner_ids: list[str] = field(default_factory=list)
    tier: str = ""  # "SCHOOL" | "COLLEGE" — mirrored from P1, never authoritative here
    booking_id: str = ""
    scheduled_start: float | None = None
    scheduled_end: float | None = None
    created_at: float = field(default_factory=time.time)
    updated_at: float = field(default_factory=time.time)
    max_capacity: int = 2  # overridden for GROUP sessions
    fail_reason: str | None = None
    cancel_reason: str | None = None

    def all_expected_user_ids(self) -> list[str]:
        return [self.tutor_id, *self.learner_ids]

    def can_transition_to(self, new_status: SessionStatus) -> bool:
        return new_status in _ALLOWED_TRANSITIONS.get(self.status, set())

    def transition_to(self, new_status: SessionStatus, *, reason: str | None = None) -> None:
        if not self.can_transition_to(new_status):
            raise InvalidStateTransitionError(
                f"Cannot transition session {self.id} from {self.status.value} to {new_status.value}."
            )
        self.status = new_status
        self.updated_at = time.time()
        if new_status == SessionStatus.FAILED:
            self.fail_reason = reason
        if new_status == SessionStatus.CANCELLED:
            self.cancel_reason = reason

    def is_terminal(self) -> bool:
        return self.status in TERMINAL_STATES

    def join_window_expired(self, grace_seconds: int, now: float | None = None) -> bool:
        if self.status != SessionStatus.WAITING or self.scheduled_start is None:
            return False
        now = now if now is not None else time.time()
        return now > (self.scheduled_start + grace_seconds)
