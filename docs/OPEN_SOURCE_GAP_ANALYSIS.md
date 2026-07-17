# MI Academy — Open Source Gap Analysis

> **Date:** 2026-07-17

---

## What exists

| Asset | Location | Status |
|-------|----------|--------|
| Dependency allowlist | `OPEN_SOURCE_AUDIT.md` | ✅ 18 approved, 5 rejected |
| Game algorithm inventory | `licenses/OPEN_SOURCE_INVENTORY.md` | ✅ 7 references |
| License decisions | `LICENSE_DECISIONS.md` | ✅ MIT/BSD/Apache-2 policy |
| Third-party notices | `THIRD_PARTY_NOTICES.md` | ⚠️ exists but needs content notices |

## What's missing

### 1. Per-game open-source scan
When building each game (Wave 2+), must scan for:
- Algorithm inspiration sources
- Test patterns borrowed
- Data structures referenced

### 2. Content asset license audit
When real audio/image assets are created, must document:
- Source of each asset
- Creator
- License
- Attribution requirement

### 3. License scanner integration
Must integrate license scanner into CI:
- `dart pub outdated` for dependency vulnerabilities
- License text extraction from `pubspec.lock`
- Automatic `NOTICES` file generation

### 4. Dependency vulnerability scan
Must run before each release:
- `dart pub outdated --no-dev`
- Check for known CVEs
- Verify maintained status of all deps

## Coverage

| Category | Current | Target | Gap |
|----------|---------|--------|-----|
| Dart deps audit | ✅ | ✅ | 0 |
| Algorithm references | ✅ | ✅ | 0 |
| Content asset audit | ❌ | ✅ | HIGH |
| License scanner in CI | ❌ | ✅ | MEDIUM |
| Vulnerability scan | ❌ | ✅ | MEDIUM |
| Third-party notices | ⚠️ | ✅ | LOW |
