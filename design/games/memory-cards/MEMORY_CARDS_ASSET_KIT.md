# Memory Cards — Asset Kit Specification v1

- **Owner:** Dev 4 | **Consumer:** Dev 2 | **Wave:** 1
- Delivery path: `games/memory_cards/assets/` per §34 contract; all IDs stable.

## 1. Kit contents

| Asset ID | Type | Size (master) | Notes |
|---|---|---|---|
| `game_memory_cardback_default_v01` | SVG | 300×400 | MI antenna motif on `color.primary`; pattern readable at 64 px wide |
| `game_memory_cardfront_frame_v01` | SVG | 300×400 | White face, `radius.large`, 3 px border `color.border` |
| `game_memory_glow_match_v01` | SVG | 320×420 | Soft `color.success` halo; reduced-motion = static appear |
| `anim_memory_cardflip_v01` | Rive | ≤ 50 KB | 3D flip 240 ms; reduced-motion = cross-fade 120 ms |
| `anim_memory_match-sparkle_v01` | Rive | ≤ 40 KB | Localized sparkle at pair |

## 2. Themes (5) — 8 pairs each, WebP 256×256 per item, < 60 KB each

| Theme | ID prefix | Items |
|---|---|---|
| Animals | `game_memory_animals_<name>_v01` | cat, dog, fish, bird, rabbit, frog, elephant, bee |
| Fruits | `game_memory_fruits_<name>_v01` | apple, banana, orange, mango, grape, watermelon, strawberry, pineapple |
| Numbers | `game_memory_numbers_<0-9>_v01` | glyph cards use `text.numberLarge`, no image needed — SVG numerals |
| Letters | `game_memory_letters_<a-z,vi>_v01` | includes Vietnamese ă â đ ê ô ơ ư; diacritics must stay legible at 64 px |
| Science | `game_memory_science_<name>_v01` | magnet, leaf, star, drop, atom, sun, moon, cloud |

Design rules: pairs must differ by **shape/silhouette**, not color alone
(color-blind safe); flat illustration per ILLUSTRATION style (to be published);
no embedded text in images (localization); background transparent.

## 3. Layout tokens

Card aspect 3:4; min card width 72 (5–7 default grids 3×4 = 6 pairs max);
grid gap `space.12`; matched cards stay visible (dimmed 60%) — never vanish
abruptly.

## 4. Audio cues (from AUDIO_DIRECTION)

`sfx_tap_card_v01`, `sfx_card_flip_v01` (replaces placeholder `card_flip.wav`),
`sfx_match_correct_v01`, `voice_mi_encourage_*_vi/en` pool (rotates, max 1 per
2 matches to avoid chatter).

## 5. Manifest

`games/memory_cards/assets/manifest.json` follows
`assets/manifests/asset_manifest.schema.json`; preload priority: cardback +
current theme only. Other themes lazy-load.

## 6. Acceptance

Pairs distinguishable in grayscale · 3×4 grid fits 360-wide phone with 56 px
targets · flip readable in reduced motion · all entries licensed
(`MI-Academy-Owned`) · Dev 3 child-safety pass on all illustrations.
