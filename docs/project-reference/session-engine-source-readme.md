# Person 2 — Video + Session Lead
## Peer-to-Peer Student Learning App — Session Engine (Python)

This repository is the Python implementation of everything owned by **Person 2** in the
project work-split: session lifecycle, 1-to-1 video, group video, chat, notifications,
and the mobile integration facade — built exactly against the phased roadmap
(`person2-roadmap.pdf`) and the folder structure defined in its Section 17.

It does **not** implement anything owned by Person 1 (auth, users, roles, age-tier
storage, payments) or Person 3 (mobile UI). Where this code needs those, it talks to a
`P1Client` stub (`session-engine/integrations/p1_client.py`) that represents the real
Person 1 backend over HTTP. Swap that stub for real HTTP calls once P1's APIs are live —
nothing else in this codebase should need to change, because every manager only ever
talks to `P1Client`, never assumes anything about tier/auth/payment itself.

## Layout

```
session-engine/
├── api/                 # FastAPI route handlers (Section 19 contract)
├── services/            # SessionManager, VideoManager, RoomManager,
│                        # ParticipantManager, ConnectionManager,
│                        # ChatManager, NotificationManager
├── providers/video/     # VideoProvider interface + AgoraProvider impl
├── models/              # Session, Participant, Conversation, Message
├── schemas/             # Pydantic request/response schemas
├── websocket/           # Chat + live-event gateway
├── core/                # config, auth middleware, typed error codes
├── integrations/        # P1Client — the only place that talks to Person 1
├── tests/               # unit / integration / security / network / load
└── docs/                # state machine diagram, API contract, decision memo

mobile-video-sdk/        # Thin client package Person 3 imports/consumes
├── session_controller.py
├── events.py
└── README.md
```

## Running it

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r session-engine/requirements.txt
uvicorn session-engine.main:app --reload --port 8001
```

## Running tests

```bash
pip install -r session-engine/requirements.txt
pytest session-engine/tests -v
```

Includes the full 10-scenario security bypass matrix from Section 14 of the roadmap
(`tests/security/test_bypass_scenarios.py`) — every one is asserted to be **rejected**.

## What's a stub vs. real logic

- **Real, working logic**: the session state machine and all its transition rules,
  RoomManager/ParticipantManager/ConnectionManager, ChatManager pagination/read-state,
  NotificationManager's typed event bus, the secure-join-flow orchestration, and all
  in-memory persistence (swap for Person 1's real DB tables per Section 18).
- **Stubbed on purpose** (because they depend on Person 1's real backend, real Agora
  credentials, or real push gateways going live): `P1Client` HTTP calls, `AgoraProvider`
  token generation (uses a placeholder signer — swap for the real Agora token builder
  after the Phase 1 POC), and FCM/APNs delivery in `NotificationManager`.
