# Asset Manifests

- **Owner:** Dev 4. Reviewers: Dev 2 (game bundles), Dev 3 (license/safety).

## Structure

```text
assets/manifests/
├── asset_manifest.schema.json   # normative schema (validate in CI)
├── app-core.manifest.json       # icons, MI character, fonts, shared UI art
├── world-map.manifest.json      # zone art (Wave 2+)
└── game.<game_id>.manifest.json # one per game — bundle loaded on-enter/lazy
```

## Rules

1. **Code references `assetId`, never filenames.** Renames/versions don't break callers.
2. Naming: `category_subject_variant_state_version` → file
   `character_mi_guide_happy_v01.webp`. Never `final.png`, `new-final-2.png`.
3. Every asset needs a `license` that resolves to
   `assets/ASSET_LICENSE_MANIFEST.json`, and `reviewStatus: approved` to ship.
4. Rive/Lottie entries MUST declare `accessibility.reducedMotionFallback`.
5. Audio entries MUST include `audioMeta` with transcript (no transcript → no ship).
6. Budgets (§23): illustration < 200 KB, background < 500 KB, checked in CI
   against `fileSizeBytes`.
7. Per-game bundles only; `preloadPolicy: eager` is reserved for `app-core`.
8. **Assets live in the package that owns the widget referencing them, not
   in `apps/mobile`.** Icons and MI character art are declared in
   `packages/design_system/pubspec.yaml` (`assets/icons/`,
   `assets/characters/mi/`) and referenced via the `packages/design_system/...`
   asset key. Flutter aggregates package-declared assets into the consuming
   app automatically — `apps/mobile` does not redeclare them.
9. **Any package with its own test suite that renders `MiIcon`/`MiCharacter`
   must set `flutter: uses-material-design: true` in its own pubspec**, even
   if it uses no Material icons. Without that flag, Flutter's tooling skips
   building the full transitive asset manifest for that package's isolated
   `flutter test` run, and `SvgPicture.asset` fails **silently** (renders
   nothing, throws nothing) — a real bug this project hit once
   (`packages/mi_game_ui`) and fixed by adding the flag. `packages/design_system`
   carries a permanent regression test (`test/asset_loading_test.dart`) that
   would have caught this immediately if it had existed first.

## Pipeline (§21)

BRIEF → SKETCH → REVIEW → FINAL → OPTIMIZE → **MANIFEST** → INTEGRATE → VISUAL QA.
An asset without a manifest entry does not exist as far as the app is concerned.
