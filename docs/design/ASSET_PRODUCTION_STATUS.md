# Asset Production Status — MI Academy

- **Owner:** Dev 4
- **Date:** 2026-07-17

## 1. Inventory (everything that exists today)

| Category | Count | Detail | Production-ready? |
|---|---|---|---|
| Images / illustrations | 0 | `apps/mobile/assets/images/` contains only `.gitkeep`; manifest lists a `placeholder.webp` that **does not exist on disk** | No |
| Character MI | 0 | No concept art, no rig, no sprite | No |
| World map | 0 | — | No |
| Icons | 0 custom | Material defaults + Unicode emoji in code | No |
| Animations (Rive/Lottie) | 0 | — | No |
| Fonts | 0 bundled | Theme names Nunito; nothing in pubspec | No |
| Audio — voice | 12 files | All **silent placeholder WAVs** (vi + en words/letters/sentences), `reviewStatus: pending` | No |
| Audio — SFX | 5 files | Silent placeholders (card_flip, correct, match_correct, try_again…) | No |
| Audio — music | 0 | — | No |
| Level data | 6 JSON | One per MVP game (Dev 2/Dev 3 owned) | n/a |

## 2. Manifest status

- `assets/ASSET_LICENSE_MANIFEST.json` exists (2 entries: nonexistent
  placeholder.webp + Unicode emoji note). Schema is reasonable; needs the
  fields required by §34 (dimensions, file size, preload priority,
  accessibility fallback). New structure: `assets/manifests/` (delivered).
- `apps/mobile/assets/audio/audio_manifest.json` exists and matches the §26
  metadata shape reasonably well (missing `audioId`, `durationMs`, `offlinePath`
  naming; uses `assetKey`/WAV). Align on the §26 schema when real audio lands.

## 3. Format & pipeline gaps

- Audio placeholders are **WAV**; production target is **OGG** (or platform
  fallback), loudness-normalized. Pipeline not yet defined → now defined in
  `docs/audio/AUDIO_DIRECTION.md`.
- No naming convention was in use (`card_flip.wav` etc. are close to spec but
  lack language/version segments). Normative convention:
  `category_subject_variant_state_version.ext` (§21).
- No asset budgets enforced. Budgets adopted: icon SVG minimal; illustration
  < 200 KB; background < 500 KB; per-game bundle loaded lazily (§23).

## 4. Production queue (ordered)

| Priority | Asset package | Blocking | Notes |
|---|---|---|---|
| P0 | Nunito font files (vi subset), OFL license entry | All text rendering | License → Dev 3 review |
| P0 | Core icon set v1 (20 icons, §19 list) | Child Home v2, game shell | SVG, own production |
| P0 | MI character: 3 concept sheets → 1 chosen → neutral/happy/thinking/celebrating poses | Everything child-facing | See `MI_CHARACTER_GUIDE.md` |
| P1 | Memory Cards asset kit (card back, frame, glow, 5 themes × 8 pairs) | Wave 1 game | Kit spec delivered |
| P1 | Voice pack vi-VN batch 1 (MI system phrases ~40 lines) | R3 risk | Script with Dev 3 |
| P1 | SFX pack v1 (tap, place, match, collect, correct, hint, complete) | Games | Replace silent WAVs |
| P2 | World map zone illustrations (6 zones × 4 states) | World map screen | After illustration style guide |
| P2 | Home/map/game/completion music loops | Polish | Ducking rules in audio doc |

## 5. Rules now in force

1. Every new asset gets a **stable asset ID** and a manifest entry before integration.
2. No asset without a license entry in `assets/ASSET_LICENSE_MANIFEST.json`.
3. No raw AI-generated output in the child app (§33 pipeline applies).
4. Per-game bundles only — nothing preloaded across games.
