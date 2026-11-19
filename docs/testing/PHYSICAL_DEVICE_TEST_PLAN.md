# Physical Device Test Plan

## Status

IMPLEMENTED: test plan template and required device coverage document created.
TESTED LOCALLY: not yet on real devices.
DEPLOYED: not yet.
VERIFIED ON PHYSICAL DEVICE: pending actual device testing.
BLOCKED BY EXTERNAL CREDENTIALS: Android/iOS devices, developer account access, and production configuration.

## Android test matrix

| Test ID | Feature | Steps | Expected result | Actual result | Pass/Fail | Device / OS |
| --- | --- | --- | --- | --- | --- | --- |
| AND-01 | Fresh install | Install app from internal build | App launches without crash | Pending | Pending | Pending |
| AND-02 | Login | Sign in with valid account | Token stored, dashboard loads | Pending | Pending | Pending |
| AND-03 | Registration | Create new learner account | Account created and verified | Pending | Pending | Pending |
| AND-04 | Course browse | Open course catalog | Listings appear | Pending | Pending | Pending |
| AND-05 | Booking | Purchase or reserve a session | Booking confirmed | Pending | Pending | Pending |
| AND-06 | Camera permission | Grant camera access | Camera preview loads | Pending | Pending | Pending |
| AND-07 | Microphone permission | Grant mic access | Audio capture available | Pending | Pending | Pending |
| AND-08 | One-to-one call | Join Agora one-to-one session | Participants connect | Pending | Pending | Pending |
| AND-09 | Group call | Join group live session | Group room connects | Pending | Pending | Pending |
| AND-10 | Notification | Trigger push or in-app notification | Notification appears and opens correctly | Pending | Pending | Pending |
| AND-11 | Network interruption | Drop connection during call | Reconnect or fail gracefully | Pending | Pending | Pending |
| AND-12 | Logout | Sign out | Token cleared and app resets | Pending | Pending | Pending |

## iOS test matrix

| Test ID | Feature | Steps | Expected result | Actual result | Pass/Fail | Device / OS |
| --- | --- | --- | --- | --- | --- | --- |
| IOS-01 | Install and launch | Install release build | App loads cleanly | Pending | Pending | Pending |
| IOS-02 | Login | Sign in | Session created | Pending | Pending | Pending |
| IOS-03 | Permissions | Allow camera and mic | Permission prompts succeed | Pending | Pending | Pending |
| IOS-04 | One-to-one call | Start video call | Participants connect | Pending | Pending | Pending |
| IOS-05 | Chat | Send/receive message | Messaging works within auth boundary | Pending | Pending | Pending |
| IOS-06 | Background mode | Background app during call | App recovers safely | Pending | Pending | Pending |

## Required manual setup before testing

- Connect a physical Android and iOS device.
- Install the app from a signed build.
- Configure valid backend environment variables.
- Configure production or staging API endpoints.
- Provide test payment credentials that do not process real funds.
- Confirm Agora credentials are valid for the target environment.

## Execution rules

- Do not mark any device test as passed without actual device verification.
- Record exact OS version, build number, network conditions, and test date.
- If a failure occurs, capture the reproduction steps and logs.
