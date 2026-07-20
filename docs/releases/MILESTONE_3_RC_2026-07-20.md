# Milestone 3 Release Candidate Notes - 2026-07-20

## Scope

- Branch: `integration/m3-games-30-release-candidate`
- Source branch: `audit/m3-games-30-verification`
- Source SHA: `0406864d1ab0f4b1d7c9558bd912d2d37c2d59dd`
- Baseline SHA / merge base: `e1f31b873d4b138465be380b42731a2afbb6276c`
- Migration head: `d2a4f8e9b730`
- App version: `0.9.0-rc.1+3`
- Package ID: `com.liemteam.miacademy`

## Catalog

- Registered games: 30
- Production levels: 1655
- Games 1-15 levels: 665
- Games 16-30 levels: 990
- Duplicate game IDs: none detected by registry/release-count tests
- Duplicate level IDs: none detected by schema validation malformed fixtures and release tests
- Solvability: all production levels solvable

## Local Validation

| Gate | Result |
|---|---|
| Ruff format | PASS after whitespace-only generator formatting |
| Ruff lint | PASS |
| MyPy | PASS, 112 source files |
| Pytest | PASS, 204 passed / 0 failed / 0 skipped |
| Shared engine format | PASS |
| Shared engine analyze | PASS |
| Shared engine tests | PASS, 169 passed / 0 failed / 0 skipped |
| Mobile format | PASS |
| Mobile analyze | PASS |
| Mobile tests | PASS, 130 passed / 0 failed / 6 skipped |
| Android integration | PASS, 28 passed / 0 failed / 0 skipped on `emulator-5554` API 36 |
| Content validation | PASS |
| Schema validation | PASS |
| Malformed fixtures | PASS, 14 correctly rejected |
| Deterministic regeneration | PASS, no content diff |
| Solvability | PASS, 1655/1655 production levels |
| Localization automation | PASS, 0 findings |
| Child/content safety | PASS, 0 fail findings |
| Offline/network audit | PASS |
| Migration head | PASS, `d2a4f8e9b730` |
| Dependency scan | PASS, no known vulnerabilities from `pip-audit` |
| SAST | PASS, Bandit no medium-or-higher findings |
| SBOM | Generated at `reports/sbom-api-rc.json` |

Mobile test skips are Windows-only pixel golden comparisons. Linux CI remains
the authoritative environment for those pixel comparisons; widget and semantic
assertions still run locally.

## Artifacts

These are non-production RC artifacts for engineering inspection. Production
signing secrets were not present, and `android/key.properties` was not present.

| File | Type | Signing | Size | SHA-256 |
|---|---|---|---:|---|
| `apps/mobile/build/app/outputs/flutter-apk/app-release.apk` | APK release-mode | DEBUG SIGNED (`CN=Android Debug`) | 58,659,496 bytes | `9079DC2C66071D830C2DB78CBC70D6954EE7415AD4BA7CDF91BF2AE698D5C2CB` |
| `apps/mobile/build/app/outputs/bundle/release/app-release.aab` | AAB release-mode | DEBUG SIGNED (`CN=Android Debug`) | 46,094,683 bytes | `65C8DF41DEB0A860F48A8CD66181150AB2F7F5C5B1CF8EB84A3D486ABB610853` |

Signing certificate SHA-256 fingerprint:
`C9:D4:1A:9A:3A:AA:C1:48:B7:12:B2:9D:25:56:49:58:3C:4D:3B:EB:DE:88:6B:E6:43:40:A0:BF:75:01:C4:9B`.

## External Gates

- Production Android signing secrets: pending
- Play Console upload access: pending
- Manual TalkBack sign-off: pending
- Manual VoiceOver sign-off: pending
- Final stakeholder publication approval: pending

The expected engineering status is RC passed with findings if CI succeeds on
the exact final RC SHA. Production publication remains blocked until the
external gates above are completed.
