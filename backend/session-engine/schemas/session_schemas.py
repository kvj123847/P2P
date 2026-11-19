from __future__ import annotations

from pydantic import BaseModel, Field


class CreateSessionRequest(BaseModel):
    booking_id: str = Field(..., description="Idempotency key — see Section 19.")


class CreateGroupSessionRequest(BaseModel):
    tutor_id: str
    learner_ids: list[str]
    tier: str
    scheduled_start: float
    scheduled_end: float


class SessionResponse(BaseModel):
    id: str
    type: str
    status: str
    tutor_id: str
    learner_ids: list[str]
    tier: str
    scheduled_start: float | None
    scheduled_end: float | None

    @classmethod
    def from_session(cls, session) -> "SessionResponse":
        return cls(
            id=session.id,
            type=session.type.value,
            status=session.status.value,
            tutor_id=session.tutor_id,
            learner_ids=session.learner_ids,
            tier=session.tier,
            scheduled_start=session.scheduled_start,
            scheduled_end=session.scheduled_end,
        )


class VideoCredentialResponse(BaseModel):
    token: str
    channel_name: str
    uid: str
    expires_at: float


class ParticipantResponse(BaseModel):
    id: str
    role: str
    audioOn: bool
    videoOn: bool
    connectionState: str


class CancelSessionRequest(BaseModel):
    reason: str = ""


class PaymentStatusWebhook(BaseModel):
    booking_id: str
    payment_status: str  # "PENDING" | "CONFIRMED" | "FAILED"
