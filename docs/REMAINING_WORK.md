# Remaining Work

## Release status

**NOT READY** for a controlled user pilot.

The Core API now builds with explicit MOCK payment boundaries, secure paid
access checks, and corrected content-review relations. The Flutter application
still uses mock state for essential flows and has no verified Agora SDK
integration.

## Completed

- Repository consolidation and naming.
- Person 1 service-token boundary.
- Payment-aware room authorization contract.
- Person 2 HTTP P1 client boundary.
- Official Agora token-builder integration structure.
- Repository structure cleaned of generated dependencies, caches, build output,
  and runtime logs.

## Must complete before a controlled user pilot

- Replace Flutter mock state with Core API calls for authentication, profile,
  discovery, booking, payments, chat, notifications, and mentor review.
- Add and verify Flutter Agora RTC lifecycle and test with two physical Android
  devices.
- Apply and verify the Prisma migration against Neon.
- Add focused integration tests for payment ownership, course fulfillment,
  session membership, chat membership, and notification ownership.
- Review dependency vulnerabilities reported by `npm ci`.

## Deliberately deferred

- Real Stripe, Stripe Connect, webhooks, and financial transfers.
- Firebase Cloud Messaging and device push delivery.
- Rewards, gamification, analytics, and recommendation enhancements.

## Production deployment phase (in progress)

- Added production-oriented server bindings, health/readiness endpoints, and tighter CORS controls in both backend services.
- Added Render deployment configuration and environment placeholders for Neon/Agora configuration.
- Added build-time configuration for the Flutter app instead of hardcoded localhost URLs.
- Live Render/Neon deployment and physical-device validation remain blocked by
  external credentials and devices.

## Blocked

- Production startup and Agora verification without credentials.
- Render/Neon deployment without external accounts and URLs.
- Android/iOS release signing and device testing without Apple/Google account access.

## Requires manual physical-device testing

- Agora audio/video, reconnection, camera/microphone state and group capacity.
- Android emulator LAN configuration and release APK validation.
- iOS signing, permissions, and device network validation.
