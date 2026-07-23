# Mi Academy Visual Asset Approval Checklist

Use this checklist before calling the generated assets final.

## Automated Gate

- `dart run tools\validate_brand_assets.dart --strict` passes.
- Home goldens pass for phone/tablet in Vietnamese and English.
- Android, Web, and Windows release builds pass.

## Human Visual Review

- Logo is recognizable at app icon size.
- Mascot matches the approved single character style.
- Mascot does not look like a real child or photo-derived image.
- All 12 mascot emotions are visually distinct.
- Brand icons are rounded, child-friendly, and readable without relying only on color.
- App icon works on light and dark launcher backgrounds.
- No emoji or random icon-pack style appears in production UI.
- Vietnamese text with diacritics remains readable in screenshots.

## Approval

Reviewer:

Date:

Decision:

- Approved for public release.
- Approved for internal/beta only.
- Needs designer replacement.

Notes:
