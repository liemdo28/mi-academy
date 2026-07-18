# Install/Upgrade Test Matrix — Internal Beta v0.9.0-beta.1

**Status: PLAN ONLY.** No physical device or distribution channel access
exists in this environment. Every scenario below is defined, none executed.

| # | Scenario | Executed? | Notes |
|---|---|---|---|
| 1 | Fresh debug install | ❌ Not executed | Requires a device |
| 2 | Fresh release install | ❌ Not executed | Requires a signed build + device |
| 3 | Upgrade from previous beta build | ❌ Not executed | No previous beta build exists yet (this is the first) |
| 4 | Reinstall over existing data | ❌ Not executed | Requires a device |
| 5 | Uninstall and reinstall | ❌ Not executed | Requires a device |
| 6 | Install with no network | ❌ Not executed | Requires a device |
| 7 | First launch after install | ❌ Not executed | Requires a device (startup-crash hardening done at the code level this pass — see hardening report §9) |
| 8 | First launch after upgrade | ❌ Not executed | N/A until a second beta build exists |
| 9 | Install with low available storage | ❌ Not executed | Requires a device |
| 10 | Interrupted install | ❌ Not executed | Requires a device |
| 11 | Corrupted cached data before upgrade | Repository-level: `openBoxWithCorruptionRecovery` (this pass) handles a corrupted Hive box without crashing startup | ❌ Not executed on a real device |
| 12 | Queued offline attempts before upgrade | Repository-level: queue items are Hive-persisted, scoped by `childProfileId`, survive process restarts by construction (verified via `flutter test` for the Hive-backed queue) | ❌ Not executed across a real app-store upgrade |

## Consequence for beta classification

All 12 scenarios require either a real device or a real distribution
channel, neither of which exists in this environment. This is the primary
reason this PR's classification is "GO WITH CAVEATS — LIMITED TECHNICAL
BETA" rather than a broader rollout recommendation.
