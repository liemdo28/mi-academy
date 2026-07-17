# Asset Production Status — MI Academy

- **Owner:** Dev 4
- **Date:** 2026-07-17 (Wave 0), updated 2026-07-17 (Wave 1), updated 2026-07-17 (Wave 2), updated 2026-07-17 (Wave 3)

## 1. Inventory (everything that exists today)

| Category | Count | Detail | Production-ready? |
|---|---|---|---|
| Images / illustrations | 0 | `apps/mobile/assets/images/` contains only `.gitkeep`; manifest lists a `placeholder.webp` that **does not exist on disk** | No |
| Character MI | 15 runtime files + 1 docs-only | Direction B "Screen-Face Companion": 1 icon-head still, 12 expression stills, 2 basic poses, bundled by `packages/design_system` (moved off `apps/mobile` — see §2 note). 1 concept sheet kept as a docs-only reference under `design/characters/`. Static SVG; Rive rig is a follow-up step. Now integrated into `ErrorState`, Word Builder, Math Race, Math Supermarket. `assets/manifests/character-mi.manifest.json` | Draft — pending Dev 3 similarity/child-safety review |
| World map | 6 zone illustrations | Alphabet City, Math Kingdom, Logic Island, Science Lab, Creative House, Achievement Garden — each a distinct silhouette (never color-only). `WorldMapScreen` now shows the real illustrated grid via `MiWorldZoneTile`; locked/in-progress/completed states applied programmatically (grayscale + badge), not as separate art. `assets/manifests/world-map.manifest.json` | Draft — pending Dev 3 review |
| Memory Cards — Animals theme | 8 pairs | cat, dog, fish, bird, rabbit, frog, elephant, bee, per `design/games/memory-cards/MEMORY_CARDS_ASSET_KIT.md`. Wired into `MemoryCardsScreen`'s card renderer via an emoji→illustration lookup with fallback to text/emoji — presentation-only, doesn't touch level data or matching logic. Only cat/dog/fish/bird are referenced by shipped level content today. `assets/manifests/game.memory_cards.manifest.json` | Draft — pending Dev 3 review |
| Icons | 21 custom (26 files incl. filled variants) | Original SVG line icons, §19 list, bundled by `packages/design_system`. `assets/manifests/app-core.manifest.json` | Draft — pending Dev 3 review |
| Animations (Rive/Lottie) | 0 | — | No |
| Fonts | 1 bundled | Nunito variable font (OFL-1.1) declared in `apps/mobile/pubspec.yaml` at weights 400/600/700/800 | Draft — pending Dev 3 license sign-off |
| Audio — voice | 12 files | All **silent placeholder WAVs** (vi + en words/letters/sentences), `reviewStatus: pending` | No |
| Audio — SFX | 5 files | Silent placeholders (card_flip, correct, match_correct, try_again…) | No |
| Audio — music | 0 | — | No |
| Level data | 6 JSON | One per MVP game (Dev 2/Dev 3 owned) | n/a |

## 1a. Wave 2 integration + a real bug found and fixed

- Replaced the `Icons.sentiment_dissatisfied_rounded` sad-face icon in both
  `MiErrorState` (design_system) and `ErrorState` (mi_game_ui) with
  `MiCharacter(expression: errorRecovery)` — the sad face directly violated
  our own rule (§12: MI never looks sad/scared, only thinking/hinting).
- Wired `MiCharacter`/`MiCharacterHead` into Word Builder's prompt card and
  the shared `ChoiceGameScreen` (Math Race + Math Supermarket) progress
  marker, replacing plain `Text('MI')` placeholders.
- Fixed a real accessibility gap in Robot Commands: command blocks were
  text-only (color-independent-feedback rule violation, §9/§18). Each
  `BlockType` now has a distinct icon + color in addition to its label.
- **Found and fixed a asset-ownership bug**: icons/character assets were
  declared only in `apps/mobile`'s pubspec even though `packages/design_system`
  owns the widgets that reference them. This worked for the real app (Flutter
  aggregates all package assets into the app bundle) but silently broke
  `SvgPicture.asset` in every *other* package's own isolated `flutter test`
  run (e.g. `mi_game_ui`'s golden tests rendered a blank box where MI's face
  should be — no error, just nothing). Fixed by moving the assets into
  `packages/design_system/assets/` and declaring them there instead; also
  had to add `flutter: uses-material-design: true` to `mi_game_ui`'s pubspec,
  which turned out to be the actual trigger Flutter's tooling checks before
  it bothers building a package's full transitive asset manifest during
  `flutter test`. Added a permanent regression test,
  `packages/design_system/test/asset_loading_test.dart`, that loads every
  icon/expression/pose and fails loudly if any of them silently return zero
  bytes. See `assets/manifests/README.md` rule 9 for the write-up.

## 1b. Wave 3 — World Map + Memory Cards art, and real accessibility

- Produced the 6 World Map zone illustrations and the 8-pair Memory Cards
  Animals theme (see inventory table above for both).
- `MiTheme.light(highContrast: ...)` now actually swaps every semantic color
  that has an `.hc` variant (primary, textPrimary, border, error) instead of
  those variants sitting unused in the token file. Wired to
  `MediaQuery.highContrastOf(context)` in `apps/mobile/lib/app.dart` — the
  platform's real "increase contrast" accessibility setting, not a fake toggle.
- `MiMotion.resolve` was defined but had **zero callers** anywhere in the
  codebase. Audited every animated widget in the app (there is exactly one:
  the Memory Cards card-flip `AnimatedContainer`) and wired it through
  `MiMotion.resolve(context, MiMotion.normal)` so reduced-motion actually
  makes the flip instant.
- Added `packages/design_system/test/mi_theme_test.dart` asserting the
  high-contrast swap and the reduced-motion resolution actually happen,
  not just that the tokens exist.
- **Test-runner gotcha found**: in this environment, bare `flutter test`
  (default concurrency) can silently drop a test file from a multi-file
  package and still report "All tests passed" — it happened to
  `packages/design_system` once a second test file existed. Re-verified with
  `flutter test --concurrency=1` (or explicit per-file counts) confirms
  nothing else was silently skipped in `mi_game_ui` or `apps/mobile`. Anyone
  running these suites locally should sanity-check the reported test count
  against the number of `testWidgets`/`test` blocks, not just trust "All
  tests passed" — the same class of silent failure as the asset-loading bug.

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
| ~~P0~~ done | Nunito font files (vi subset), OFL license entry | All text rendering | Bundled; **Dev 3 sign-off still pending** |
| ~~P0~~ done | Core icon set v1 (21 icons, §19 list) | Child Home v2, game shell | Bundled via `MiIcon`; **Dev 3 review still pending** |
| ~~P0~~ done | MI character: 3 concept sheets → 1 chosen → 12 expressions + 2 poses | Everything child-facing | Bundled via `MiCharacter`; **Dev 3 similarity/safety review still pending**; Rive rig not started |
| ~~P1~~ done | Memory Cards Animals theme (8 pairs) | Wave 1 game | Full 5-theme kit still only has Animals done; Fruits/Numbers/Letters/Science themes remain |
| P1 | Voice pack vi-VN batch 1 (MI system phrases ~40 lines) | R3 risk | Script with Dev 3 |
| P1 | SFX pack v1 (tap, place, match, collect, correct, hint, complete) | Games | Replace silent WAVs |
| ~~P2~~ done | World map zone illustrations (6 zones) | World map screen | One illustration per zone; locked/in-progress/completed done programmatically, not as separate art (see §23 budget) |
| P2 | Home/map/game/completion music loops | Polish | Ducking rules in audio doc |

All done items above have `reviewStatus: draft` / `approved: false` in
their manifests — they are wired into the running app but not yet cleared
by Dev 3. Treat them as provisional until sign-off lands.

## 5. Rules now in force

1. Every new asset gets a **stable asset ID** and a manifest entry before integration.
2. No asset without a license entry in `assets/ASSET_LICENSE_MANIFEST.json`.
3. No raw AI-generated output in the child app (§33 pipeline applies).
4. Per-game bundles only — nothing preloaded across games.
