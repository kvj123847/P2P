# Play Store Release Checklist

## Status

IMPLEMENTED: release checklist and environment-based config structure prepared.
TESTED LOCALLY: not yet.
DEPLOYED: not yet.
VERIFIED ON PHYSICAL DEVICE: not yet.
BLOCKED BY EXTERNAL CREDENTIALS: Android signing certificate, Google Play console permissions, and device testing access.

## Android release checklist

- Confirm app ID and package name.
- Configure remote API endpoint for production.
- Add Android release signing config.
- Generate keystore securely and keep it outside the repo.
- Build an internal testing APK.
- Generate an AAB for Play Store review.
- Verify camera, microphone, internet, and notification permissions in Android manifests.
- Validate app startup, registration, login, session booking, and payment flow.

## iOS release checklist

- Confirm bundle identifier and signing identity.
- Configure app transport security for production endpoints.
- Add required camera and microphone permissions.
- Validate Apple provisioning profile and push notification entitlement.
- Generate an archive in Xcode and validate device install.

## Notes

- Never commit keystores, passwords, or provisioning secrets.
- Keep a separate release environment for production endpoints.
- Confirm that all manual release actions are run by an authorized maintainer.
