# Device QA Matrix — Internal Beta v0.9.0-beta.1

**Status: PLAN ONLY — not executed.** No physical iOS/Android device or
emulator has been available at any point in this environment. Every row
below is a defined test plan, not a completed result. Do not read any row
as "passed" — nothing here has real evidence yet.

## Minimum recommended Android coverage

| # | Device class | Target | Executed? |
|---|---|---|---|
| 1 | Low-memory Android | e.g. 2GB RAM, budget tier | ❌ Not executed |
| 2 | Mid-range Android | e.g. 4-6GB RAM | ❌ Not executed |
| 3 | Recent Android | current-gen flagship-tier | ❌ Not executed |
| — | OS version spread | at least 2 Android OS versions across the above | ❌ Not executed |

## Minimum recommended iOS coverage

| # | Device class | Target | Executed? |
|---|---|---|---|
| 1 | Older supported iPhone | oldest iOS version the app targets | ❌ Not executed |
| 2 | Recent iPhone | current-gen | ❌ Not executed |
| — | OS version spread | at least 2 supported iOS versions | ❌ Not executed |

## Per-device test cases (to run on every device above, once available)

| Case | Description |
|---|---|
| Install | Fresh install from the distribution channel |
| Launch | Cold start, warm start |
| Sign in | Register + login flow |
| Child selection | Select/create a child profile |
| Each game | All 6 games: launch, play, complete |
| Audio | Sound Match's audio playback |
| Rotation | If orientation change is supported |
| Background/resume | App backgrounded mid-game, resumed |
| Offline completion | Complete a game with airplane mode on |
| Reconnect | Disable then re-enable network mid-sync |
| App kill | Force-kill during gameplay, during sync |
| Restart | Cold restart after kill |
| Logout | Logout, re-login |
| Child switching | Switch between 2+ children |
| Text scaling | OS-level large text setting |
| Reduced motion | OS-level reduce-motion setting (Memory Cards) |
| Screen reader | TalkBack (Android) / VoiceOver (iOS) on critical flows |
| Battery behavior | No excessive battery drain from sync retry loop |
| Storage behavior | No unbounded local storage growth |

## Worksheet template (fill in per device once testing begins)

| Field | Value |
|---|---|
| Device model | |
| OS version | |
| App build | |
| Tester | |
| Test date | |
| Test cases run | |
| Result | |
| Evidence (screenshot/video/log) | |
| Defects found | |
| Retest status | |

## Consequence for beta classification

Per this PR's own entry criteria: **if real-device testing has not occurred
at all, classification must be "GO WITH CAVEATS — LIMITED TECHNICAL BETA,"
not a broad-rollout GO.** As of this document's creation, zero rows above
have real evidence — that caveat applies.
