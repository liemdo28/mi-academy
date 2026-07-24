# Known Limitations

Last updated: 2026-07-24 on `integration/m1-m2-baseline`.

## Release Blockers

- **Manual child-safety QA is pending.** Automated audits pass for 30 games, but `docs/child-safety/GAME_SAFETY_PRESIGNOFF.md` still requires a human reviewer/date for real-device review.
- **Full UI localization is not complete.** ARB parity passes at 97 English keys and 97 Vietnamese keys, but `python tools/localization_audit.py --json` still reports 211 hardcoded user-facing string warnings across 50 mobile files after the first localization cleanup pass.
- **Real-device coverage is not complete in this environment.** Windows local verification covered analyzer, widget/golden tests, web build, APK, and AAB. iOS/macOS tooling and a physical-device or emulator playthrough signoff still need to be attached by release QA.
- **Final brand/content approval is still human-owned.** All 37 required brand assets pass the strict validator, but the generated mascot/logo/icon candidates still need designer ownership/licensing approval before public store release.
- **Admin CMS publishing workflow remains incomplete.** The child app has bundled content, but a full publish/unpublish/version/rollback CMS workflow is still a later product phase.

## Non-Blocking Warnings

- Child-safety static audit warns about `dio` and `connectivity_plus`; these are expected for parent/sync/backend flows and must stay out of child-facing game mechanics.
- Platform privacy audit warns about INTERNET permission in debug/profile Android manifests; release manifests are still scoped separately.
- Flutter reports 28 dependency updates available but incompatible with current constraints. This is not a build failure.

## Verified Closures

- 30 of 30 target games are registered and content-backed.
- 1030 production levels validate through the mobile/backend content schema path.
- Android release APK and AAB build successfully.
- Android signing configuration is present.
- Home Screen has phone/tablet Vietnamese/English golden previews with no overflow test failures.
