"""
App entrypoint. Run with:
    uvicorn session-engine.main:app --reload --port 8001
(from the repo root, with session-engine's parent on PYTHONPATH — or `cd
session-engine && uvicorn main:app --reload`).
"""
from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI, WebSocket
from fastapi.responses import JSONResponse

from api import chat, notifications, sessions, video
from core.config import settings
from core.errors import SessionEngineError
from deps import get_chat_manager
from websocket.gateway import chat_websocket_endpoint


@asynccontextmanager
async def lifespan(app: FastAPI):
    mock_summary = None
    if settings.dev_mock_data:
        from dev.mock_data import seed_mock_p1_data

        mock_summary = seed_mock_p1_data()
    app.state.mock_data = mock_summary
    yield


app = FastAPI(
    title="Peer-to-Peer Learning App — Session Engine (Person 2)",
    version="0.1.0",
    lifespan=lifespan,
)

app.include_router(sessions.router)
app.include_router(video.router)
app.include_router(chat.router)
app.include_router(notifications.router)


@app.exception_handler(SessionEngineError)
async def handle_session_engine_error(request, exc: SessionEngineError):
    """Shared error envelope (status code + typed error code + safe
    message), per Section 19."""
    return JSONResponse(status_code=exc.http_status, content=exc.to_envelope())


@app.websocket("/ws/conversations/{conversation_id}")
async def ws_conversation(websocket: WebSocket, conversation_id: str, token: str, last_received_message_id: str | None = None):
    await chat_websocket_endpoint(
        websocket,
        conversation_id,
        token,
        get_chat_manager(),
        last_received_message_id=last_received_message_id,
    )


@app.get("/health")
async def health():
    out: dict = {"status": "ok", "service": "session-engine", "environment": "production" if settings.environment == "production" else "development"}
    if settings.dev_mock_data and getattr(app.state, "mock_data", None) is not None:
        m = app.state.mock_data
        out["devMockData"] = {
            "bookingId": m.college_booking_id,
            "pendingBookingId": m.pending_booking_id,
            "tokens": {
                "collegeTutor": m.college_tutor_token,
                "collegeLearner": m.college_learner_token,
                "schoolTutor": m.school_tutor_token,
            },
        }
    return out


@app.get("/livez")
async def livez():
    return {"status": "alive", "service": "session-engine"}


@app.get("/readyz")
async def readyz():
    has_p1_config = bool(settings.p1_base_url and settings.p1_service_token)
    status_code = 200 if has_p1_config else 503
    payload = {
        "status": "ready" if has_p1_config else "not_ready",
        "service": "session-engine",
        "p1_configured": has_p1_config,
    }
    return JSONResponse(status_code=status_code, content=payload)
