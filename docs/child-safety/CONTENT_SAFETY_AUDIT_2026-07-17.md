# MI Academy — Content Safety Audit

> Date: 2026-07-17
> Scope: Authored MVP level JSON in `apps/mobile/assets/levels/`

## Result

`python tools/content_safety_audit.py --json` passes locally.

```json
{
  "status": "pass",
  "files_scanned": 6,
  "strings_scanned": 1904,
  "summary": {
    "fail": 0,
    "warn": 0
  }
}
```

## Coverage

The audit scans all child-facing strings in the six MVP game content files:

- Word Builder
- Sound Match
- Math Race
- Math Supermarket
- Memory Cards
- Robot Commands

It fails on external links, social/leaderboard language, purchase or subscription language, harsh or punitive feedback, sensitive-data requests, and pressure wording. It also checks level metadata for positive `timeLimitSec` values because countdown timers can create pressure for children.

## Changes Made

- `apps/mobile/assets/levels/math_race.json`: all MVP `timeLimitSec` metadata is now `0`.
- `tools/content_safety_audit.py`: Vietnamese privacy matching distinguishes child-data requests such as GPS/location services from ordinary card-position wording like "vị trí" in Memory Cards hints.

## Remaining Manual Work

This automated audit does not replace manual child-safety review. A per-game reviewer still needs to verify visual tone, MI voice, accessibility, offline behavior, and age appropriateness on a real device or emulator.
