"""
Auth-header middleware/dependency (Phase 4: "Introduce the API
Client/Repository layer: centralized auth headers...").

This module never decides *who* a user is beyond what P1 says. It just
extracts the bearer token and hands verification to `P1Client`, per the
secure video join flow (Section 14):

    mobile calls backend (with auth token)
    -> backend verifies authentication [P1]
"""
from __future__ import annotations

from fastapi import Header

from core.errors import UnauthenticatedError
from integrations.p1_client import Identity, get_p1_client


async def get_current_identity(authorization: str | None = Header(default=None)) -> Identity:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise UnauthenticatedError("Missing bearer token.")
    token = authorization.split(" ", 1)[1].strip()
    if not token:
        raise UnauthenticatedError("Empty bearer token.")
    client = get_p1_client()
    return await client.verify_token(token)
