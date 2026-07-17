# Game License Review

**Date:** 2026-07-17
**Policy:** Only MIT, BSD, Apache-2.0, CC0 permitted. NO GPL, AGPL, LGPL.

## 1. Package License Summary

| Package | License | Status |
|---------|---------|--------|
| mi_game_core | MIT | COMPLIANT |
| mi_game_ui | MIT | COMPLIANT |
| mi_game_audio | MIT | COMPLIANT |
| mi_game_accessibility | MIT | COMPLIANT |
| mi_game_testing | MIT | COMPLIANT |
| mi_blocks | MIT | COMPLIANT |
| Flutter SDK | BSD-3-Clause | COMPLIANT |
| equatable | BSD-3-Clause | COMPLIANT |
| audioplayers | MIT | COMPLIANT |
| uuid | BSD-3-Clause | COMPLIANT |
| mocktail | BSD-3-Clause | COMPLIANT |
| golden_toolkit | BSD-3-Clause | COMPLIANT |
| flutter_lints | MIT | COMPLIANT |

## 2. Game Asset Licenses

All game assets (images, audio, fonts) are documented in `assets/ASSET_LICENSE_MANIFEST.json`.

See `docs/OPEN_SOURCE_AUDIT.md` for full asset audit.

## 3. Third-Party Notices

See `THIRD_PARTY_NOTICES.md` in root for required attribution notices.

## 4. Closed-Source Game Protection

Games are loaded via the `MiGame` interface. The interface is open (MIT), but individual game implementations are in the private `apps/` directory and are NOT published as open-source.

## 5. Compliance Declaration

All packages in the MI Academy monorepo use only permitted licenses (MIT, BSD-3-Clause, Apache-2.0, CC0). No GPL, AGPL, or copyleft licenses are used. Third-party assets are documented with their original licenses in ASSET_LICENSE_MANIFEST.json.
