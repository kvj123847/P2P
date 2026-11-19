"""
Session + video-credential endpoints, matching the Section 19 API contract
table exactly:

  POST /sessions                     -> create_session_from_booking (idempotent via booking_id)
  GET  /sessions/:id                 -> get_session
  POST /sessions/:id/cancel          -> cancel_session
  POST /sessions/:id/start           -> start_session (WAITING -> LIVE happens implicitly on join,
                                         but an explicit tutor-initiated "start" is exposed too)
  POST /sessions/:id/video-token     -> get_video_credential
  POST /sessions/:id/join            -> join_session
  POST /sessions/:id/leave           -> leave_session
  POST /sessions/:id/complete        -> complete_session
  GET  /sessions/:id/participants    -> get_participants
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, Header

from core.auth import get_current_identity
from deps import get_session_manager
from integrations.p1_client import Identity
from models.session import SessionStatus
from schemas.session_schemas import (
    CancelSessionRequest,
    CreateGroupSessionRequest,
    CreateSessionRequest,
    ParticipantResponse,
    PaymentStatusWebhook,
    SessionResponse,
    VideoCredentialResponse,
)
from services.session_manager import SessionManager

router = APIRouter(prefix="/sessions", tags=["sessions"])


@router.post("", response_model=SessionResponse, status_code=201)
async def create_session(
    body: CreateSessionRequest,
    identity: Identity = Depends(get_current_identity),
    sessions: SessionManager = Depends(get_session_manager),
):
    session = await sessions.create_session_from_booking(body.booking_id)
    return SessionResponse.from_session(session)


@router.post("/group", response_model=SessionResponse, status_code=201)
async def create_group_session(
    body: CreateGroupSessionRequest,
    identity: Identity = Depends(get_current_identity),
    sessions: SessionManager = Depends(get_session_manager),
):
    session = sessions.create_group_session(
        tutor_id=body.tutor_id,
        learner_ids=body.learner_ids,
        tier=body.tier,
        scheduled_start=body.scheduled_start,
        scheduled_end=body.scheduled_end,
    )
    return SessionResponse.from_session(session)


@router.get("/{session_id}", response_model=SessionResponse)
async def get_session(
    session_id: str,
    identity: Identity = Depends(get_current_identity),
    sessions: SessionManager = Depends(get_session_manager),
):
    session = await sessions.assert_caller_is_participant(session_id, identity.user_id)
    return SessionResponse.from_session(session)


@router.post("/{session_id}/cancel", response_model=SessionResponse)
async def cancel_session(
    session_id: str,
    body: CancelSessionRequest,
    identity: Identity = Depends(get_current_identity),
    sessions: SessionManager = Depends(get_session_manager),
):
    session = await sessions.cancel(session_id, identity.user_id, reason=body.reason)
    return SessionResponse.from_session(session)


@router.post("/{session_id}/start", response_model=SessionResponse)
async def start_session(
    session_id: str,
    identity: Identity = Depends(get_current_identity),
    sessions: SessionManager = Depends(get_session_manager),
):
    """Only valid from WAITING (Section 19). In this MVP, LIVE is normally
    entered automatically on first successful join; this endpoint exists
    for a tutor-initiated explicit "go live" UX if Person 3 wants one."""
    session = await sessions.assert_caller_is_participant(session_id, identity.user_id)
    if session.status == SessionStatus.WAITING:
        session.transition_to(SessionStatus.LIVE)
    return SessionResponse.from_session(session)


@router.post("/{session_id}/video-token", response_model=VideoCredentialResponse)
async def get_video_credential(
    session_id: str,
    authorization: str = Header(default=""),
    identity: Identity = Depends(get_current_identity),
    sessions: SessionManager = Depends(get_session_manager),
):
    """Implements the full secure join flow, Section 14. TTL ~5-10 min."""
    token = await sessions.request_join_credential(
        session_id,
        identity.user_id,
        authorization.removeprefix("Bearer ").strip(),
    )
    return VideoCredentialResponse(
        token=token.token, channel_name=token.channel_name, uid=token.uid, expires_at=token.expires_at
    )


@router.post("/{session_id}/join", response_model=VideoCredentialResponse)
async def join_session(
    session_id: str,
    authorization: str = Header(default=""),
    identity: Identity = Depends(get_current_identity),
    sessions: SessionManager = Depends(get_session_manager),
):
    """Emits PARTICIPANT_JOINED (Section 19) — modeled here as issuing the
    credential, which is the action that actually admits the participant."""
    token = await sessions.request_join_credential(
        session_id,
        identity.user_id,
        authorization.removeprefix("Bearer ").strip(),
    )
    return VideoCredentialResponse(
        token=token.token, channel_name=token.channel_name, uid=token.uid, expires_at=token.expires_at
    )


@router.post("/{session_id}/leave", status_code=204)
async def leave_session(
    session_id: str,
    identity: Identity = Depends(get_current_identity),
    sessions: SessionManager = Depends(get_session_manager),
):
    """Idempotent — calling leave twice is a no-op the second time."""
    sessions.leave(session_id, identity.user_id)
    return None


@router.post("/{session_id}/complete", response_model=SessionResponse)
async def complete_session(
    session_id: str,
    identity: Identity = Depends(get_current_identity),
    sessions: SessionManager = Depends(get_session_manager),
):
    session = await sessions.complete(session_id, identity.user_id)
    return SessionResponse.from_session(session)


@router.get("/{session_id}/participants", response_model=list[ParticipantResponse])
async def get_participants(
    session_id: str,
    identity: Identity = Depends(get_current_identity),
    sessions: SessionManager = Depends(get_session_manager),
):
    """Participant-only visibility (Section 19) — enforced via
    assert_caller_is_participant before the roster is ever read."""
    await sessions.assert_caller_is_participant(session_id, identity.user_id)
    roster = sessions.participant_manager.roster(session_id)
    return [ParticipantResponse(**p.to_public_dict()) for p in roster]
