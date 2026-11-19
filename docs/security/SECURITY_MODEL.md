# Security Model

## Trust boundaries

- Person 1 is authoritative for JWT identity, roles, age tier, bookings,
  payment status and persistent records.
- Person 2 accepts an end-user bearer token and calls Person 1 before issuing
  any Agora credential.
- Flutter only stores short-lived access credentials and renders server
  decisions; local filtering is UX only.

## Room authorization

Person 2 calls:

`POST /api/v1/sessions/:sessionId/authorize-room`

with both the end-user `Authorization: Bearer ...` header and the private
`X-Service-Token` header. Person 1 verifies the JWT, account status, age-tier
compatibility, session membership, booking confirmation and successful payment
for paid sessions. Person 1 returns room metadata only. Person 2 then creates
the short-lived Agora token.

The Agora App Certificate and service token are server-only secrets.

## Known limitations

- Persistent chat storage and push notification delivery are not yet wired.
- The session engine's process-local presence state is not durable across
  restarts.
- Real Agora credentials, HTTPS service URLs and physical-device tests are
  required before deployment.

