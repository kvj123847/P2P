"""HTTP boundary to Person 1's authoritative core API.

The fake implementation remains available only for explicit DEV_MOCK_DATA
tests. Production code always uses the HTTP client and never trusts client
supplied identity, tier, booking, or payment fields.
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any

import httpx

from core.config import settings
from core.errors import (
    NotAParticipantError,
    PaymentNotConfirmedError,
    TierMismatchError,
    UnauthenticatedError,
    ValidationError,
)


@dataclass
class Identity:
    user_id: str
    tier: str
    roles: list[str] = field(default_factory=list)
    account_status: str = "ACTIVE"


@dataclass
class BookingRecord:
    booking_id: str
    tutor_id: str
    learner_id: str
    tier: str
    payment_status: str
    slot_start: float
    slot_end: float


@dataclass
class RoomAuthorization:
    session_id: str
    room_id: str
    user_id: str
    role: str
    user_age_tier: str
    session_age_tier: str
    session_status: str


class P1ClientInterface(ABC):
    @abstractmethod
    async def verify_token(self, bearer_token: str) -> Identity:
        ...

    @abstractmethod
    async def authorize_room_access(self, bearer_token: str, session_id: str) -> RoomAuthorization:
        ...

    @abstractmethod
    async def get_booking(self, booking_id: str) -> BookingRecord:
        ...

    @abstractmethod
    async def check_tier_compatible(self, user_ids: list[str]) -> bool:
        ...

    @abstractmethod
    async def is_session_participant(self, user_id: str, session_id: str) -> bool:
        ...

    @abstractmethod
    async def notify_session_completed(self, session_id: str, participant_ids: list[str]) -> None:
        ...

    @abstractmethod
    async def notify_session_cancelled(self, session_id: str, reason: str) -> None:
        ...


class HttpP1Client(P1ClientInterface):
    def __init__(self) -> None:
        if not settings.p1_base_url or not settings.p1_service_token:
            raise RuntimeError("P1_BASE_URL and P1_SERVICE_TOKEN are required")
        self._base_url = settings.p1_base_url.rstrip("/")
        self._service_headers = {"X-Service-Token": settings.p1_service_token}

    async def _request(
        self,
        method: str,
        path: str,
        *,
        bearer_token: str | None = None,
        json: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        headers = dict(self._service_headers)
        if bearer_token:
            headers["Authorization"] = f"Bearer {bearer_token}"
        try:
            async with httpx.AsyncClient(
                base_url=self._base_url,
                timeout=settings.p1_timeout_seconds,
            ) as client:
                response = await client.request(method, path, headers=headers, json=json)
        except httpx.HTTPError as exc:
            raise ValidationError("Person 1 authorization service is unavailable") from exc

        if response.status_code in (401, 403):
            raise UnauthenticatedError("Person 1 rejected authorization")
        if response.status_code == 404:
            raise NotAParticipantError("Session or booking is not available")
        if response.status_code == 402:
            raise PaymentNotConfirmedError("Payment is not confirmed")
        if response.status_code >= 400:
            raise ValidationError("Person 1 rejected the request")
        body = response.json()
        if not isinstance(body, dict) or not body.get("success", True):
            raise ValidationError("Invalid response from Person 1")
        return body

    async def verify_token(self, bearer_token: str) -> Identity:
        body = await self._request("GET", "/api/v1/auth/me", bearer_token=bearer_token)
        user = body.get("data", {}).get("user", {})
        try:
            identity = Identity(
                user_id=str(user["id"]),
                tier=str(user["ageTier"]),
                roles=[str(role) for role in user.get("roles", [])],
                account_status=str(user["accountStatus"]),
            )
        except (KeyError, TypeError) as exc:
            raise ValidationError("Invalid identity response from Person 1") from exc
        if identity.account_status != "ACTIVE":
            raise UnauthenticatedError("Account is not active")
        return identity

    async def authorize_room_access(self, bearer_token: str, session_id: str) -> RoomAuthorization:
        body = await self._request(
            "POST",
            f"/api/v1/sessions/{session_id}/authorize-room",
            bearer_token=bearer_token,
        )
        data = body.get("data", {})
        try:
            return RoomAuthorization(
                session_id=str(data["sessionId"]),
                room_id=str(data["roomId"]),
                user_id=str(data["userId"]),
                role=str(data["role"]),
                user_age_tier=str(data["userAgeTier"]),
                session_age_tier=str(data["sessionAgeTier"]),
                session_status=str(data.get("sessionStatus", "SCHEDULED")),
            )
        except (KeyError, TypeError) as exc:
            raise ValidationError("Invalid room authorization response from Person 1") from exc

    async def get_booking(self, booking_id: str) -> BookingRecord:
        body = await self._request("GET", f"/api/v1/sessions/internal/bookings/{booking_id}")
        data = body.get("data", {})
        try:
            return BookingRecord(
                booking_id=str(data["bookingId"]),
                tutor_id=str(data["tutorId"]),
                learner_id=str(data["learnerId"]),
                tier=str(data["tier"]),
                payment_status=str(data["paymentStatus"]),
                slot_start=float(data["slotStart"]),
                slot_end=float(data["slotEnd"]),
            )
        except (KeyError, TypeError, ValueError) as exc:
            raise ValidationError("Invalid booking response from Person 1") from exc

    async def check_tier_compatible(self, user_ids: list[str]) -> bool:
        # Group membership is authorized by P1's session endpoint. This
        # compatibility method is retained for the in-memory test contract.
        return len(user_ids) <= 1

    async def is_session_participant(self, user_id: str, session_id: str) -> bool:
        return False

    async def notify_session_completed(self, session_id: str, participant_ids: list[str]) -> None:
        await self._request(
            "POST",
            f"/api/v1/sessions/internal/{session_id}/completed",
            json={"participantIds": participant_ids},
        )

    async def notify_session_cancelled(self, session_id: str, reason: str) -> None:
        await self._request(
            "POST",
            f"/api/v1/sessions/internal/{session_id}/cancelled",
            json={"reason": reason},
        )


class FakeP1Client(P1ClientInterface):
    """Explicit test double; never selected unless DEV_MOCK_DATA is enabled."""

    def __init__(self) -> None:
        self._identities: dict[str, Identity] = {}
        self._bookings: dict[str, BookingRecord] = {}
        self._participants: dict[str, set[str]] = {}

    def register_identity(self, token: str, identity: Identity) -> None:
        self._identities[token] = identity

    def register_booking(self, booking: BookingRecord) -> None:
        self._bookings[booking.booking_id] = booking

    def register_participant(self, session_id: str, user_id: str) -> None:
        self._participants.setdefault(session_id, set()).add(user_id)

    async def verify_token(self, bearer_token: str) -> Identity:
        identity = self._identities.get(bearer_token)
        if identity is None or identity.account_status != "ACTIVE":
            raise UnauthenticatedError("Invalid or expired token")
        return identity

    async def authorize_room_access(self, bearer_token: str, session_id: str) -> RoomAuthorization:
        identity = await self.verify_token(bearer_token)
        if not await self.is_session_participant(identity.user_id, session_id):
            raise NotAParticipantError()
        return RoomAuthorization(session_id, f"room-{session_id}", identity.user_id, "PARTICIPANT", identity.tier, identity.tier, "SCHEDULED")

    async def get_booking(self, booking_id: str) -> BookingRecord:
        booking = self._bookings.get(booking_id)
        if booking is None:
            raise NotAParticipantError("Booking not found")
        return booking

    async def check_tier_compatible(self, user_ids: list[str]) -> bool:
        tiers = {
            identity.tier
            for identity in self._identities.values()
            if identity.user_id in user_ids
        }
        return len(tiers) <= 1

    async def is_session_participant(self, user_id: str, session_id: str) -> bool:
        return user_id in self._participants.get(session_id, set())

    async def notify_session_completed(self, session_id: str, participant_ids: list[str]) -> None:
        return None

    async def notify_session_cancelled(self, session_id: str, reason: str) -> None:
        return None


def get_p1_client() -> P1ClientInterface:
    return FakeP1Client() if settings.dev_mock_data else HttpP1Client()
