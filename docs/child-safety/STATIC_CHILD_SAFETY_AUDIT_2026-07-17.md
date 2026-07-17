# MI Academy Static Child Safety Audit — 2026-07-17

## Scope

Automated static scan of the Flutter mobile app source, `pubspec.yaml`, Android main manifest, and iOS `Info.plist`.

This audit checks for prohibited MVP child-app patterns from the product brief:

- Advertising SDKs or ad widgets
- In-app purchase or subscription SDKs
- Social sign-in, social feeds, friends, or leaderboards
- External URL launchers
- Sensitive mobile permissions such as camera, microphone, location, contacts, tracking, or advertising ID
- Pressure/loss-aversion wording and harsh failure wording

## Command

`python tools/child_safety_audit.py --json`

## Result

| Metric | Result |
|--------|--------|
| Status | Pass |
| Files scanned | 28 |
| Hard failures | 0 |
| Warnings | 2 |

## Warnings

| Category | File | Reason |
|----------|------|--------|
| Network | `apps/mobile/pubspec.yaml` | `dio` is present for backend sync/API use |
| Network | `apps/mobile/pubspec.yaml` | `connectivity_plus` is present for offline/sync state |

## Interpretation

- No ad, IAP, social, external-link launcher, sensitive permission, or harsh/pressure wording hard failures were detected in the scanned mobile scope.
- No hardcoded backend URL is embedded in the scanned mobile source. The API client is offline-first by default and requires an explicit `MI_ACADEMY_API_BASE_URL` build-time value for parent/sync backend use.
- Parent settings local persistence/export code is included in the scanned source and did not add hard failures.
- Remaining network dependency warnings are expected for parent reports, sync, and backend API support, but release QA must still verify child-facing gameplay remains offline-first and does not require network access after content download.
- This is not a substitute for manual child-safety review. The checklist still requires per-game review and sign-off.
