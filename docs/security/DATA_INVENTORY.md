# Data Inventory

Date: 2026-07-24

## Child-Facing App

- Local child profile selection state.
- Local game progress, attempts, mastery signals, rewards, and snapshots.
- Bundled offline level content.
- No advertising, chat, social sharing, or in-game purchase surfaces were found by automated audits.

## Parent/Sync Surfaces

- Parent authentication/session data.
- Parent settings, including language and reduced-motion preferences.
- Optional backend sync paths for progress and reports.
- Network dependencies are present for parent/sync/backend use and are tracked by child-safety audit warnings.

## Release Notes

- INTERNET permission warnings are present in debug/profile Android manifests only and should be reviewed during release QA.
- No direct personal contact/payment identifiers should be added to child-facing flows.
- Manual privacy review remains required before public store submission.
