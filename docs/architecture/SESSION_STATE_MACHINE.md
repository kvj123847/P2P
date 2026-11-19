# Session State Machine (Phase 0 deliverable)

```mermaid
stateDiagram-v2
    [*] --> CREATED
    CREATED --> PENDING_PAYMENT
    CREATED --> CANCELLED
    PENDING_PAYMENT --> CONFIRMED
    PENDING_PAYMENT --> FAILED
    PENDING_PAYMENT --> CANCELLED
    CONFIRMED --> SCHEDULED
    CONFIRMED --> CANCELLED
    SCHEDULED --> WAITING
    SCHEDULED --> CANCELLED
    WAITING --> LIVE
    WAITING --> FAILED
    WAITING --> CANCELLED
    LIVE --> COMPLETED
    LIVE --> FAILED
    COMPLETED --> [*]
    CANCELLED --> [*]
    FAILED --> [*]
```

This table is enforced in code by `models/session.py::_ALLOWED_TRANSITIONS` —
any call to `Session.transition_to()` outside this table raises
`InvalidStateTransitionError`. See `person2-roadmap.pdf` Section 4 for the
full narrative (failure/edge-case rules, timeouts, reconnection behavior).
