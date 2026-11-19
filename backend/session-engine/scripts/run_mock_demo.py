"""
Exercise the session-engine HTTP API using dev mock P1 data.

Start the server first:
    set DEV_MOCK_DATA=true
    uvicorn main:app --port 8001

Then:
    python scripts/run_mock_demo.py
"""
from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request

from dev.mock_data import (
    MOCK_BOOKING_COLLEGE_CONFIRMED,
    MOCK_BOOKING_PAYMENT_PENDING,
    MOCK_TOKEN_COLLEGE_LEARNER,
    MOCK_TOKEN_COLLEGE_TUTOR,
    MOCK_TOKEN_SCHOOL_TUTOR,
)

BASE = os.getenv("SESSION_ENGINE_URL", "http://127.0.0.1:8001").rstrip("/")


def request(method: str, path: str, *, token: str | None = None, body: dict | None = None) -> tuple[int, object]:
    url = f"{BASE}{path}"
    data = None
    headers = {"Accept": "application/json"}
    if body is not None:
        data = json.dumps(body).encode("utf-8")
        headers["Content-Type"] = "application/json"
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            raw = resp.read().decode("utf-8")
            return resp.status, json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8")
        try:
            payload = json.loads(raw)
        except json.JSONDecodeError:
            payload = raw
        return e.code, payload


def step(name: str, ok: bool, detail: str = "") -> None:
    tag = "PASS" if ok else "FAIL"
    line = f"  [{tag}] {name}"
    if detail:
        line += f" — {detail}"
    print(line)
    if not ok:
        raise SystemExit(1)


def main() -> None:
    print(f"Mock API demo against {BASE}\n")

    code, health = request("GET", "/health")
    step("health", code == 200 and isinstance(health, dict) and health.get("status") == "ok")
    if not health.get("devMockData"):
        print(
            "\n  Hint: restart uvicorn with DEV_MOCK_DATA=true so mock tokens are loaded.\n"
            f"  Expected tokens: tutor={MOCK_TOKEN_COLLEGE_TUTOR}\n"
        )
        raise SystemExit(1)

    code, session = request(
        "POST",
        "/sessions",
        token=MOCK_TOKEN_COLLEGE_TUTOR,
        body={"booking_id": MOCK_BOOKING_COLLEGE_CONFIRMED},
    )
    step("create 1:1 session from confirmed booking", code == 201, str(session))
    session_id = session["id"]

    code, cred_tutor = request("POST", f"/sessions/{session_id}/join", token=MOCK_TOKEN_COLLEGE_TUTOR)
    step("tutor join + video token", code == 200 and bool(cred_tutor.get("token")))

    code, cred_learner = request("POST", f"/sessions/{session_id}/join", token=MOCK_TOKEN_COLLEGE_LEARNER)
    step(
        "learner join (same channel)",
        code == 200 and cred_learner.get("channel_name") == cred_tutor.get("channel_name"),
    )

    code, session_live = request("GET", f"/sessions/{session_id}", token=MOCK_TOKEN_COLLEGE_TUTOR)
    step("session is LIVE", code == 200 and session_live.get("status") == "LIVE")

    code, roster = request("GET", f"/sessions/{session_id}/participants", token=MOCK_TOKEN_COLLEGE_TUTOR)
    step("participants roster", code == 200 and len(roster) >= 2)

    code, convo = request(
        "POST",
        "/conversations",
        token=MOCK_TOKEN_COLLEGE_TUTOR,
        body={
            "session_id": session_id,
            "participant_ids": [session_live["tutor_id"], *session_live["learner_ids"]],
            "tier": "COLLEGE",
        },
    )
    step("create conversation", code == 201)
    conv_id = convo["id"]

    code, msg = request(
        "POST",
        f"/conversations/{conv_id}/messages",
        token=MOCK_TOKEN_COLLEGE_TUTOR,
        body={"body": "Hello from mock tutor"},
    )
    step("send chat message", code == 201)

    code, messages = request("GET", f"/conversations/{conv_id}/messages", token=MOCK_TOKEN_COLLEGE_LEARNER)
    step("learner reads messages", code == 200 and len(messages) >= 1)

    code, notes = request("GET", "/notifications", token=MOCK_TOKEN_COLLEGE_LEARNER)
    step("notifications outbox", code == 200 and isinstance(notes, list))

    code, _ = request("POST", f"/sessions/{session_id}/leave", token=MOCK_TOKEN_COLLEGE_TUTOR)
    step("tutor leave", code == 204)
    code, _ = request("POST", f"/sessions/{session_id}/leave", token=MOCK_TOKEN_COLLEGE_LEARNER)
    step("learner leave", code == 204)

    code, done = request("GET", f"/sessions/{session_id}", token=MOCK_TOKEN_COLLEGE_TUTOR)
    step("session COMPLETED", code == 200 and done.get("status") == "COMPLETED")

    code, pending_session = request(
        "POST",
        "/sessions",
        token=MOCK_TOKEN_COLLEGE_TUTOR,
        body={"booking_id": MOCK_BOOKING_PAYMENT_PENDING},
    )
    step("create session from pending-payment booking", code == 201)
    pending_id = pending_session["id"]
    step("pending session not joinable yet", pending_session.get("status") == "PENDING_PAYMENT")

    code, join_fail = request("POST", f"/sessions/{pending_id}/join", token=MOCK_TOKEN_COLLEGE_TUTOR)
    step("join blocked until payment confirmed", join_fail != 200)

    code, confirmed = request(
        "POST",
        "/webhooks/payment-status",
        body={"booking_id": MOCK_BOOKING_PAYMENT_PENDING, "payment_status": "CONFIRMED"},
    )
    step("payment webhook confirms session", code == 200 and confirmed.get("status") == "WAITING")

    code, _ = request("POST", f"/sessions/{pending_id}/join", token=MOCK_TOKEN_COLLEGE_TUTOR)
    step("join after payment webhook", code == 200)

    code, tier_fail = request("POST", f"/sessions/{pending_id}/join", token=MOCK_TOKEN_SCHOOL_TUTOR)
    step("school tutor cannot join college session", tier_fail != 200)

    print("\nAll mock-data checks passed.")


if __name__ == "__main__":
    main()
