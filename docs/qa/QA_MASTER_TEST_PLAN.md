# MI Academy — QA Master Test Plan

> **Version:** 1.0.0
> **Date:** 2026-07-17
> **Owner:** Dev 3 — Content, QA & Release Lead

---

## 1. Test layers

### Layer 1: Unit tests (per package)

| Package | What to test | Minimum |
|---------|-------------|---------|
| `mi_game_core` | Lifecycle state transitions, model serialization, snapshot round-trip | 22 tests ✅ |
| `mi_game_content` | Content validator (valid/invalid JSON), loader, provider caching | 16 tests ✅ |
| `mi_game_audio` | Volume settings, ducking logic, metadata serialization | 16 tests ✅ |
| `mi_game_progress` | Mastery calculation, attempt recording, difficulty recommendation | 15 tests ✅ |
| `mi_game_accessibility` | AccessibilityHelper calculations, MotionConfig durations | 8 tests |
| `mi_blocks` | Command tree validation, interpreter execution, direction math | 22 tests ✅ |
| `offline_sync` | Queue persistence, offline retention, retry, privacy-safe payloads | 5 tests ✅ |
| `mi_game_ui` | Widget rendering, child-safe shared states, and visual baselines | 20 tests ✅; includes 8 golden tests |
| Content validators | Level schema, skill ID existence, localization completeness | 20 tests ✅ |
| `apps/mobile` | MVP game surfaces, parent flows, game-slice visual baselines, gentle retry/hint interactions, Memory Cards save/restore, and Word/Sound/Choice session save/restore | 40 widget/golden/save-restore tests ✅ |

### Layer 2: Contract tests

| Contract | What to verify |
|----------|---------------|
| Game → Platform | MiGame interface is correctly implemented |
| Content → Game | Level JSON is parseable by game engine |
| Snapshot → Restore | Serialized state restores correctly |
| Skill → Progress | Skill IDs in content exist in taxonomy |
| Asset → Content | Referenced assets exist and are approved |
| Localization → Content | All required locales present |

### Layer 3: Integration tests

| Flow | Steps verified |
|------|---------------|
| App launch → game play | App opens, level loads, cards display, tap works |
| App launch → profile/parent entry | Exploration hub shows child profile, rewards, offline status, and parent area entry |
| Game completion → progress | Level completes, stars awarded, progress saved |
| Save/restore | Close mid-game, reopen, state restored correctly |
| Parent settings persistence | Parent changes language/offline/export state, reopens settings, and sees saved values |
| Offline → online | Play offline, reconnect, data syncs |
| Parent dashboard | Local parent report shows gentle progress summary; backend progress data remains separate verification |
| Parent API report/export/delete | FastAPI parent report summarizes sessions, parent export returns privacy-safe JSON without raw answers, and child deletion removes child-owned data |

### Layer 4: E2E tests

| Scenario | Device coverage |
|----------|----------------|
| Full onboarding flow | Phone + tablet |
| Play Memory Cards level 1–3 | Phone + tablet |
| Play all 6 MVP games | Phone + tablet |
| Switch language mid-session | Phone + tablet |
| Complete with reduced motion | Phone + tablet |
| Delete child profile | Phone + tablet |

### Layer 5: Accessibility tests

| Check | Method |
|-------|--------|
| Minimum touch target 48×48 | Automated layout inspection |
| Screen reader labels | Widget test with semantics |
| High contrast mode | Visual golden test |
| Reduced motion | MotionConfig + zero-duration assertions |
| Tap alternative for drag | Manual + automated test |
| Extended response time | Timer assertion |
| Color-independent feedback | Icon + text presence check |
| Subtitle display | Subtitle visibility assertion |

### Layer 6: Privacy tests

| Check | Method |
|-------|--------|
| No outbound HTTP from game code | `tools/game_network_audit.py` static gate + runtime smoke |
| No ad SDK in dependency tree | `pubspec.lock` scan |
| No GPS/camera/contact API calls | Grep source + permission manifest |
| No advertising identifier | Grep for `advertisingId` |
| Parent gate present | UI test |
| No external links in child mode | Manual review + grep |

### Layer 7: Performance tests

| Metric | Target | Method |
|--------|--------|--------|
| Cold start | < 3s | Stopwatch measurement |
| Game load | < 2s | Stopwatch measurement |
| Frame rate | 60fps stable | Frame timing callback |
| Memory | < 200MB | DevTools memory tab |
| Save latency | < 500ms | Stopwatch measurement |
| Restore latency | < 500ms | Stopwatch measurement |

---

## 2. Bug severity definitions

| Severity | Definition | Release impact |
|----------|-----------|----------------|
| P0 | Data loss, security breach, crash loop, license violation | BLOCKS release |
| P1 | Game unbeatable, save/restore broken, wrong educational content | BLOCKS release |
| P2 | Significant UI issue, missing language, incorrect hint | Does NOT block but must fix |
| P3 | Cosmetic, alignment, minor copy | Fix when convenient |

---

## 3. Release gate criteria

All of the following must be true:

- [ ] Zero P0 bugs
- [ ] Zero P1 bugs
- [ ] All content validators pass
- [ ] All contract tests pass
- [ ] All unit tests pass
- [ ] Child safety checklist: 10/10 per game
- [ ] Accessibility checklist: pass per game
- [ ] Privacy checklist: pass per game
- [ ] Performance targets met
- [ ] Vietnamese + English content complete
- [ ] License audit clear
- [ ] Release score ≥ 85/100 per game

---

## 4. Test execution schedule

| Phase | Tests | Frequency |
|-------|-------|-----------|
| Development | Unit + contract | Every commit |
| PR review | Unit + contract + content validation | Every PR |
| Integration | Integration + accessibility | Daily |
| Pre-release | Full E2E + privacy + performance | Before each release |

---

## 5. Bug report template

```
**Title:** [Game Name] — Brief description
**Severity:** P0/P1/P2/P3
**Environment:** iOS/Android/Web + version
**Build:** commit hash
**Device:** model + screen size
**Language:** vi/en
**Age group:** junior/explorer/master
**Precondition:** What state was the app in
**Steps to reproduce:**
1. ...
2. ...
3. ...
**Expected result:** What should happen
**Actual result:** What actually happened
**Screenshot/recording:** [attached]
**Logs:** [if available]
**Regression:** New / Existing / Unknown
**Owner:** [name]
```
