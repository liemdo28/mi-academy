# MI Academy Production Audio Audit — 2026-07-17

## Scope

Strict release-readiness audit for bundled mobile audio assets.

This is different from `tools/content_validator/validate_content.py`, which
allows silent placeholder WAV files so the MVP can run locally. The production
audio audit fails until every audio asset is a reviewed, non-placeholder
recording with non-zero duration and approved manifest metadata.

## Command

`python tools/production_audio_audit.py --json`

## Result

| Metric | Result |
|--------|--------|
| Status | Fail |
| Assets scanned | 18 |
| Approved assets | 0 |
| Placeholder assets | 18 |
| Findings | 72 failures |

## Why It Fails

Every current audio asset is a silent placeholder WAV. Each asset fails the
production gate because:

- the WAV has zero duration
- `placeholder` is `true`
- `reviewStatus` is not `approved`
- `speaker` is still `placeholder`

## Release Interpretation

This is a correct release blocker. MI Academy can continue local MVP testing
with placeholder audio, but Release 0.2 must not be marked production-ready
until reviewed voice/effect recordings replace the placeholders and the audit
passes.

## Required Fix

For each asset in `apps/mobile/assets/audio/audio_manifest.json`:

1. Replace the 44-byte silent WAV with a real child-safe recording.
2. Set `placeholder` to `false`.
3. Set `reviewStatus` to `approved` after content/safety review.
4. Replace `speaker: "placeholder"` with an approved speaker/source.
5. Keep transcripts filled for localized voice assets.
