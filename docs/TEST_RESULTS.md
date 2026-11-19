# Test Results

## Baseline before integration

- Core API: not run; dependencies were absent.
- Session engine: `python -m pytest -q` reported 20 passed and 21 failed because
  async tests were unsupported by the active environment.
- Flutter: `flutter analyze` reported one existing `UserRole.canTeach` error.

## Integration validation

- Core API: `npm run build` passed.
- Core API: `npm test -- --runInBand` passed (4 suites, 32 tests).
- Session engine: installed `requirements.txt` in
  `backend/session-engine/.venv`; `python -m pytest -q` passed (41 tests).
- Flutter: `flutter pub get`, `flutter analyze`, and `flutter test` passed.
- Flutter's former `UserRole.canTeach` analyzer issue was fixed by importing the
  model extension source.
- The paid-room safety test now verifies that an unpaid booking is rejected
  before room authorization.

Local production-hardening checks: core API health/readiness endpoints, Render deployment scaffolding,
service host binding, and stronger CORS allowlists were implemented.

No service is marked production-ready until real cross-service, Agora, Neon, Render, and
physical-device security tests pass with live external credentials.
