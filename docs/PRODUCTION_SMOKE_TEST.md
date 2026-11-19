# Production Smoke Test

Run these checks only after configuring secrets and applying migrations:

1. `GET /health` returns `200`.
2. `GET /readyz` returns `200` and reports the database connected.
3. Session Engine `/health` and `/readyz` return `200`.
4. Register and log in two users in the same age tier.
5. Confirm a different age tier cannot discover or access the same course/session.
6. Submit content, verify it is absent from public discovery, approve it as a verified mentor, then publish it.
7. Create a paid course checkout. Confirm it is labelled `DEMO PAYMENT`.
8. Attempt enrollment before simulation and confirm `403`.
9. Simulate success only through the protected server-side control token, then confirm enrollment and lesson access.
10. Simulate failure and confirm it grants no access.
11. Verify each user can list and mark only their own notifications.
12. Verify chat and session access with a non-member returns `403`.

The mobile app and Agora flow remain unverified until Flutter API integration and two-device testing are completed.

