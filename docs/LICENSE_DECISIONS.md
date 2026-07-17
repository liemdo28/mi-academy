# MI Academy — License Decisions

> **Audit date:** 2026-07-17
> **Scope:** Foundation Sprint — Phase A
> **Status:** Complete

---

## 1. MI Academy license

The MI Academy project itself is **proprietary**.
No open-source license is applied to MI Academy source code, assets, content,
or documentation.

---

## 2. Approved license families

| License    | Allowed | Notes |
|------------|---------|-------|
| MIT        | ✅      | Full attribution required in NOTICES |
| BSD-2/3    | ✅      | Full attribution required in NOTICES |
| Apache-2.0 | ✅      | Attribution + NOTICE file; patent grant beneficial |
| ISC        | ✅      | Same as MIT effectively |
| MPL-2.0    | ⚠️      | Allowed only if dependency is NOT modified; file-level copyleft |
| LGPL       | ❌      | Linking obligations too complex for mobile stores |
| GPL        | ❌      | Copyleft — forces source disclosure |
| AGPL       | ❌      | Network copyleft — absolutely excluded |
| CC-BY-SA   | ❌      | Copyleft on content/assets |
| CC-BY-NC   | ❌      | Non-commercial — incompatible |
| Unlicensed | ❌      | Cannot legally redistribute |

---

## 3. Decision rationale

### Why no GPL/LGPL

MI Academy targets iOS App Store and Google Play. GPL's requirement to provide
full source code conflicts with proprietary business model. LGPL adds linking
complexity on mobile where static linking is the norm. Safer to exclude entirely.

### Why Apache-2.0 is fine

Apache-2.0 provides an explicit patent grant, which is valuable. The attribution
requirement is satisfied via `NOTICES` file bundled in the app.

### Why MPL-2.0 requires caution

MPL-2.0 is file-level copyleft. If we modify any MPL-2.0 file, that file must
be shared under MPL-2.0. We only accept MPL-2.0 dependencies we use unmodified
via pub.dev packages.

### Why no copyleft content licenses

Game content (questions, levels, illustrations, audio) uses CC-BY-SA or GPL-style
content licenses — these force us to share derivative content. All MI Academy
content must remain proprietary.

---

## 4. Third-party notice process

1. Every approved dependency is listed in `OPEN_SOURCE_AUDIT.md`.
2. A `NOTICES` file in the app bundle includes all required attribution.
3. `melos run generate_notices` script auto-collects license text from
   `pubspec.lock` resolved packages.
4. This