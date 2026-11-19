# Repository Structure

The integrated repository uses stable, responsibility-based names instead of
the original wrapper names:

- `backend/core-api/` — Person 1's authoritative Express/Prisma service.
- `backend/session-engine/` — Person 2's FastAPI orchestration service.
- `mobile/` — Person 3's Flutter application.
- `docs/project-reference/` — source analysis and non-production reference material.
- `tests/integration/` and `tests/e2e/` — future cross-service test suites.

Files inside each project retain standard ecosystem names and existing internal
module names so package tooling, imports and test discovery remain compatible.

