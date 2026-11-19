"""
Typed error codes shared across the service.

Section 19 of the roadmap requires: "All error responses follow a shared
envelope (status code + typed error code + safe message)". These exceptions
carry that envelope and are translated to HTTP responses in api/ via
FastAPI exception handlers (see main.py).

Security note (Section 14): error messages must NEVER leak whether a
resource exists to a caller who is not authorized to know that (e.g.
"invalid session id" vs "you are not a participant" should look identical
from outside).
"""
from __future__ import annotations

from enum import Enum


class ErrorCode(str, Enum):
    UNAUTHENTICATED = "UNAUTHENTICATED"
    NOT_FOUND_OR_FORBIDDEN = "NOT_FOUND_OR_FORBIDDEN"  # deliberately ambiguous, see note above
    INVALID_STATE_TRANSITION = "INVALID_STATE_TRANSITION"
    TIER_MISMATCH = "TIER_MISMATCH"
    PAYMENT_NOT_CONFIRMED = "PAYMENT_NOT_CONFIRMED"
    DUPLICATE_BOOKING = "DUPLICATE_BOOKING"
    ROOM_AT_CAPACITY = "ROOM_AT_CAPACITY"
    TOKEN_EXPIRED = "TOKEN_EXPIRED"
    NOT_A_PARTICIPANT = "NOT_A_PARTICIPANT"
    VALIDATION_ERROR = "VALIDATION_ERROR"
    PROVIDER_UNAVAILABLE = "PROVIDER_UNAVAILABLE"
    INTERNAL_ERROR = "INTERNAL_ERROR"


class SessionEngineError(Exception):
    """Base class for every error this service raises intentionally."""

    http_status: int = 400
    code: ErrorCode = ErrorCode.INTERNAL_ERROR

    def __init__(self, message: str = "", *, code: ErrorCode | None = None, http_status: int | None = None):
        super().__init__(message)
        self.message = message or self.code.value
        if code is not None:
            self.code = code
        if http_status is not None:
            self.http_status = http_status

    def to_envelope(self) -> dict:
        return {
            "error": {
                "code": self.code.value,
                "message": self.message,
            }
        }


class UnauthenticatedError(SessionEngineError):
    http_status = 401
    code = ErrorCode.UNAUTHENTICATED


class NotFoundOrForbiddenError(SessionEngineError):
    """
    Used instead of separate 404 / 403 errors wherever distinguishing them
    would leak information about a resource's existence to a non-participant
    (Section 19: "404 vs 403 must not leak existence to non-participants").
    """
    http_status = 404
    code = ErrorCode.NOT_FOUND_OR_FORBIDDEN

    def __init__(self, message: str = "Not found."):
        super().__init__(message)


class InvalidStateTransitionError(SessionEngineError):
    http_status = 409
    code = ErrorCode.INVALID_STATE_TRANSITION


class TierMismatchError(SessionEngineError):
    http_status = 403
    code = ErrorCode.TIER_MISMATCH

    def __init__(self, message: str = "Tier mismatch."):
        super().__init__(message)


class PaymentNotConfirmedError(SessionEngineError):
    http_status = 402
    code = ErrorCode.PAYMENT_NOT_CONFIRMED


class DuplicateBookingError(SessionEngineError):
    http_status = 409
    code = ErrorCode.DUPLICATE_BOOKING


class RoomAtCapacityError(SessionEngineError):
    http_status = 409
    code = ErrorCode.ROOM_AT_CAPACITY


class TokenExpiredError(SessionEngineError):
    http_status = 401
    code = ErrorCode.TOKEN_EXPIRED


class NotAParticipantError(SessionEngineError):
    http_status = 403
    code = ErrorCode.NOT_A_PARTICIPANT

    def __init__(self, message: str = "Not a participant."):
        super().__init__(message)


class ValidationError(SessionEngineError):
    http_status = 422
    code = ErrorCode.VALIDATION_ERROR


class ProviderUnavailableError(SessionEngineError):
    http_status = 503
    code = ErrorCode.PROVIDER_UNAVAILABLE
