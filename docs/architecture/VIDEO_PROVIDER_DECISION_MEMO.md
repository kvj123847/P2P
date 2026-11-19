# Video Provider Decision Memo — Phase 1 POC

**Status: DRAFT — fill in after running the Phase 1 POC on real devices.**

## Candidates evaluated
Agora, Twilio Video, Stream Video (comparison table: `person2-roadmap.pdf` Section 3).

## POC results (fill in)
| Test | Agora | Twilio | Stream |
|---|---|---|---|
| 1-to-1 call — 2 physical devices | | | |
| Group call — 3+ physical devices | | | |
| Wi-Fi → mobile data mid-call | | | |
| Forced network drop / reconnection | | | |
| Measured cost/min at expected concurrency | | | |
| RN/Flutter SDK maturity (whichever P3 picks) | | | |

## Recommendation
Pending POC — roadmap's working assumption is **Agora** based on the
comparison table (strongest 1-to-1 + group track record, competitive
pricing, mature reconnection). This is `AgoraProvider` in
`providers/video/agora_provider.py`, built behind the `VideoProvider`
interface so switching to Twilio or Stream later means writing one new
provider file, not touching any manager or API route.

## Go/no-go
Record the go/no-go decision here before Phase 2 begins, per Section 5.
