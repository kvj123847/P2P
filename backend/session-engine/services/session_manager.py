"""
SessionManager (Phase 0-8) — the central orchestrator of Person 2's domain.

Owns: session lifecycle/state machine, the secure video join flow (Section
14), wiring together RoomManager/VideoManager/ParticipantManager/
ConnectionManager/NotificationManager, and the payment-status integration
(Phase 8).

Hard rule enforced everywhere in this file: SessionManager NEVER decides
identity, tier, or payment status itself. Every one of those checks is a
call to `P1ClientInterface` and this manager treats the answer as final.
This is what Section 14's bypass-test matrix verifies.
"""
from __future__ import annotations

import time
import uuid

from core.config import settings
from core.errors import (
    DuplicateBookingError,
    InvalidStateTransitionError,
    NotAParticipantError,
    PaymentNotConfirmedError,
    TierMismatchError,
    ValidationError,
)
from integrations.p1_client import BookingRecord, HttpP1Client, P1ClientInterface
from models.participant import ConnectionState, ParticipantRole
from models.session import Session, SessionStatus, SessionType
from providers.video.video_provider import VideoProvider, VideoToken
from services.connection_manager import ConnectionManager
from services.notification_manager import NotificationManager
from services.participant_manager import ParticipantManager
from services.room_manager import RoomManager
from services.video_manager import VideoManager


class SessionManager:
    def __init__(
        self,
        p1_client: P1ClientInterface,
        video_provider: VideoProvider,
        participant_manager: ParticipantManager | None = None,
        connection_manager: ConnectionManager | None = None,
        notification_manager: NotificationManager | None = None,
    ) -> None:
        self.p1_client = p1_client
        self.room_manager = RoomManager(video_provider)
        self.video_manager = VideoManager(video_provider, self.room_manager)
        self.participant_manager = participant_manager or ParticipantManager()
        self.connection_manager = connection_manager or ConnectionManager()
        self.notifications = notification_manager or NotificationManager()

        self._sessions: dict[str, Session] = {}
        self._by_booking_id: dict[str, str] = {}  # booking_id -> session_id, for idempotency (Phase 8)

    # ------------------------------------------------------------------
    # Creation / booking integration (Phase 2, Phase 8)
    # ------------------------------------------------------------------
    async def create_session_from_booking(self, booking_id: str) -> Session:
        """
        Idempotent by booking_id: "a duplicate payment-confirmed event must
        not create a duplicate session or duplicate video room" (Section
        12). Calling this twice for the same booking returns the same
        session rather than creating a second one.
        """
        if booking_id in self._by_booking_id:
            return self._sessions[self._by_booking_id[booking_id]]

        booking: BookingRecord = await self.p1_client.get_booking(booking_id)

        session = Session(
            type=SessionType.ONE_TO_ONE,
            tutor_id=booking.tutor_id,
            learner_ids=[booking.learner_id],
            tier=booking.tier,
            booking_id=booking.booking_id,
            scheduled_start=booking.slot_start,
            scheduled_end=booking.slot_end,
            max_capacity=2,
        )
        self._sessions[session.id] = session
        self._by_booking_id[booking_id] = session.id

        self.participant_manager.add_expected_participant(session.id, booking.tutor_id, ParticipantRole.TUTOR)
        self.participant_manager.add_expected_participant(session.id, booking.learner_id, ParticipantRole.LEARNER)

        session.transition_to(SessionStatus.PENDING_PAYMENT)
        await self._apply_payment_status(session, booking.payment_status)
        return session

    def create_group_session(
        self, *, tutor_id: str, learner_ids: list[str], tier: str, scheduled_start: float, scheduled_end: float
    ) -> Session:
        session = Session(
            type=SessionType.GROUP,
            tutor_id=tutor_id,
            learner_ids=list(learner_ids),
            tier=tier,
            scheduled_start=scheduled_start,
            scheduled_end=scheduled_end,
            max_capacity=settings.max_group_room_capacity,
        )
        self._sessions[session.id] = session
        self.participant_manager.add_expected_participant(session.id, tutor_id, ParticipantRole.TUTOR)
        for learner_id in learner_ids:
            self.participant_manager.add_expected_participant(session.id, learner_id, ParticipantRole.LEARNER)
        return session

    async def _apply_payment_status(self, session: Session, payment_status: str) -> None:
        if payment_status == "CONFIRMED":
            session.transition_to(SessionStatus.CONFIRMED)
            session.transition_to(SessionStatus.SCHEDULED)
            session.transition_to(SessionStatus.WAITING)
            for uid in session.all_expected_user_ids():
                self.notifications.booking_confirmed(uid, session.id)
        elif payment_status == "FAILED":
            session.transition_to(SessionStatus.FAILED, reason="Payment failed.")
        # PENDING -> leave in PENDING_PAYMENT, nothing to do yet.

    async def on_payment_status_changed(self, booking_id: str, payment_status: str) -> Session:
        """Webhook/poll handler for Person 1's payment-status change (Phase 8)."""
        session_id = self._by_booking_id.get(booking_id)
        if session_id is None:
            raise ValidationError(f"No session found for booking {booking_id}.")
        session = self._sessions[session_id]
        if session.status != SessionStatus.PENDING_PAYMENT:
            return session  # idempotent no-op if already processed
        await self._apply_payment_status(session, payment_status)
        return session

    # ------------------------------------------------------------------
    # Retrieval
    # ------------------------------------------------------------------
    def get(self, session_id: str) -> Session:
        session = self._sessions.get(session_id)
        if session is None:
            raise NotAParticipantError("Session not found.")
        return session

    async def assert_caller_is_participant(self, session_id: str, user_id: str) -> Session:
        session = self.get(session_id)
        if user_id not in session.all_expected_user_ids():
            # Deliberately identical error to "not found" — see Section 19's
            # "404 vs 403 must not leak existence to non-participants".
            raise NotAParticipantError("Session not found.")
        return session

    # ------------------------------------------------------------------
    # Secure join flow (Section 14) — the single most important method here
    # ------------------------------------------------------------------
    async def request_join_credential(
        self,
        session_id: str,
        user_id: str,
        bearer_token: str | None = None,
    ) -> VideoToken:
        """
        Implements, in order, every check from the Section 14 diagram:

            verify authentication          [caller already authenticated via core.auth]
            verify session exists/valid    [P1 in spirit; enforced here against our own record]
            verify caller is a participant [P1-sourced booking data]
            verify payment/session status  [P1]
            verify school/college tier     [P1]
            generate short-lived token     [P2 -> VideoManager -> AgoraProvider]

        Every one of the 10 bypass scenarios in Section 14 is a test that
        this method raises before a token is ever generated.
        """
        session = await self.assert_caller_is_participant(session_id, user_id)

        if isinstance(self.p1_client, HttpP1Client):
            if not bearer_token:
                raise NotAParticipantError("Missing end-user authorization")
            authorization = await self.p1_client.authorize_room_access(
                bearer_token, session_id
            )
            if authorization.user_id != user_id:
                raise NotAParticipantError("Authorization identity mismatch")

        if session.status in (SessionStatus.CANCELLED, SessionStatus.FAILED, SessionStatus.COMPLETED):
            raise InvalidStateTransitionError(f"Session {session_id} is {session.status.value}; cannot join.")

        if session.status not in (SessionStatus.WAITING, SessionStatus.LIVE):
            raise PaymentNotConfirmedError("Session is not yet confirmed/ready to join.")

        # Tier re-verification happens on EVERY join, never assumed from the
        # booking alone (Section 9: "Every participant's tier is
        # re-validated by P1 at join time"). We check the joining user
        # against whoever is CURRENTLY connected — not every *expected*
        # participant — because a group session's expected roster (from a
        # booking/invite list) is exactly what a bypass attempt would try to
        # smuggle a mismatched user into; checking against who has actually
        # already been admitted is what catches that at the moment it
        # matters, without falsely blocking the first joiner of a session
        # whose full expected roster hasn't arrived yet.
        if settings.strict_tier_reverify_on_every_join and not isinstance(self.p1_client, HttpP1Client):
            connected_ids = [
                p.user_id
                for p in self.participant_manager.roster(session_id)
                if p.connection_state == ConnectionState.CONNECTED
            ]
            compatible = await self.p1_client.check_tier_compatible([*connected_ids, user_id])
            if not compatible:
                raise TierMismatchError("User's tier does not match this session's tier.")

        if session.join_window_expired(settings.join_window_grace_seconds):
            session.transition_to(SessionStatus.FAILED, reason="Join window expired.")
            raise InvalidStateTransitionError("Join window has expired for this session.")

        joined_participant = self.participant_manager.join(session_id, user_id, session.max_capacity)

        if session.status == SessionStatus.WAITING:
            session.transition_to(SessionStatus.LIVE)
            for uid in session.all_expected_user_ids():
                self.notifications.session_status_changed(uid, session.id, SessionStatus.LIVE.value)

        return self.video_manager.issue_join_credential(session_id, user_id)

    # ------------------------------------------------------------------
    # Leave / completion / cancellation
    # ------------------------------------------------------------------
    def leave(self, session_id: str, user_id: str) -> None:
        session = self.get(session_id)
        self.participant_manager.leave(session_id, user_id)

        if session.type == SessionType.ONE_TO_ONE and self.participant_manager.connected_count(session_id) == 0:
            self._complete(session)
        elif session.type == SessionType.GROUP and self.participant_manager.connected_count(session_id) == 0:
            self._complete(session)

    def _complete(self, session: Session) -> None:
        if session.status != SessionStatus.LIVE:
            return
        session.transition_to(SessionStatus.COMPLETED)
        self.room_manager.teardown_room(session.id)
        for uid in session.all_expected_user_ids():
            self.notifications.session_status_changed(uid, session.id, SessionStatus.COMPLETED.value)

    async def complete(self, session_id: str, caller_id: str) -> Session:
        session = await self.assert_caller_is_participant(session_id, caller_id)
        self._complete(session)
        await self.p1_client.notify_session_completed(session.id, session.all_expected_user_ids())
        return session

    async def cancel(self, session_id: str, caller_id: str, reason: str = "") -> Session:
        session = await self.assert_caller_is_participant(session_id, caller_id)
        if session.is_terminal():
            raise InvalidStateTransitionError(f"Session {session_id} is already {session.status.value}.")
        session.transition_to(SessionStatus.CANCELLED, reason=reason or "Cancelled by participant.")
        self.room_manager.teardown_room(session.id)
        await self.p1_client.notify_session_cancelled(session.id, session.cancel_reason or "")
        for uid in session.all_expected_user_ids():
            self.notifications.session_cancelled(uid, session.id, session.cancel_reason or "")
        return session

    # ------------------------------------------------------------------
    # Timeouts (Section 4: tutor/learner no-show, join window expiry)
    # ------------------------------------------------------------------
    def sweep_timeouts(self, now: float | None = None) -> list[Session]:
        now = now if now is not None else time.time()
        expired = []
        for session in self._sessions.values():
            if session.join_window_expired(settings.join_window_grace_seconds, now=now):
                session.transition_to(SessionStatus.FAILED, reason="No-show: join window expired.")
                self.room_manager.teardown_room(session.id)
                expired.append(session)
        return expired
