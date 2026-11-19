# Production Deployment Audit

Audit date: 2026-11-15

## Status

**NOT READY** for a controlled user pilot. The Core API has been hardened and builds, but Flutter still uses mock application state and Agora has not been integrated into the mobile package.

## Findings

| Priority | Finding | Status |
| --- | --- | --- |
| P0 | A shared `contentId` was foreign-keyed to both courses and sessions. | Fixed with separate nullable foreign keys and an exactly-one database check. |
| P0 | Payment code could initialize Stripe and create real transfers. | Fixed: only the explicitly gated MOCK provider remains. |
| P0 | Paid course enrollment did not require a successful payment. | Fixed: enrollment and lesson access require a succeeded MOCK payment. |
| P1 | Paid session booking could remain pending without successful payment. | Fixed: paid booking requires a succeeded payment. |
| P1 | Unreviewed sessions were discoverable. | Fixed in the available-session query by requiring an approved review. |
| P1 | Flutter uses local mock state for core flows. | Open; must be replaced with API-backed state. |
| P1 | Flutter has no Agora SDK dependency or verified video lifecycle. | Open; physical-device verification is required. |
| P2 | Notification storage exists but push delivery is not implemented. | Deliberately mocked; in-app storage is the release behavior. |
| P2 | Existing dependency audit reports vulnerabilities. | Open; review and upgrade in a separate dependency-maintenance change. |
| P2 | Core API lint command has no checked-in ESLint configuration. | Open; TypeScript build passes. |
| P1 | Android release build fails because the project uses deleted Android v1 embedding. | Open; Flutter tests and analysis pass. |

## Database safety

The follow-up migration is non-destructive to unrelated tables, but it changes the review table shape. Run `npx prisma migrate status` against the target database first. Do not run `prisma migrate reset` against Neon or any shared database.

Local migration status could not be verified in this environment because the
configured PostgreSQL credentials were rejected.

