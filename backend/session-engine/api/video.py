"""
Payment/session integration webhook (Phase 8) — Person 1's backend calls
this when a booking's payment status changes. If no webhook exists yet on
P1's side, poll `P1Client` and call `on_payment_status_changed` from a
scheduled job instead; the SessionManager method is the same either way.
"""
from __future__ import annotations

from fastapi import APIRouter, Depends

from core.auth import get_current_identity
from deps import get_session_manager
from schemas.session_schemas import PaymentStatusWebhook, SessionResponse
from services.session_manager import SessionManager

router = APIRouter(prefix="/webhooks", tags=["video-session-integration"])


@router.post("/payment-status", response_model=SessionResponse)
async def payment_status_changed(
    body: PaymentStatusWebhook,
    sessions: SessionManager = Depends(get_session_manager),
):
    """
    Authenticated separately from user-facing bearer tokens in production
    (e.g. a shared service secret or signed webhook payload from P1) —
    left as an open TEAM decision per the roadmap; not gated by
    get_current_identity since the caller here is Person 1's service, not
    an end user.
    """
    session = await sessions.on_payment_status_changed(body.booking_id, body.payment_status)
    return SessionResponse.from_session(session)
