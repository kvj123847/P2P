"""
GET /notifications (Section 19) — Person 2 owns the events; push infra is
shared/P1 concern. This endpoint lets Person 3's mobile app poll/backfill
notifications it may have missed while offline (push is the primary path).
"""
from __future__ import annotations

from fastapi import APIRouter, Depends

from core.auth import get_current_identity
from deps import get_notification_manager
from integrations.p1_client import Identity
from services.notification_manager import NotificationManager

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("")
async def list_notifications(
    identity: Identity = Depends(get_current_identity),
    notifications: NotificationManager = Depends(get_notification_manager),
):
    outbox = notifications.outbox_for(identity.user_id)
    return [
        {"event": p.event.value, "createdAt": p.created_at, **p.sanitized()}
        for p in outbox
    ]
