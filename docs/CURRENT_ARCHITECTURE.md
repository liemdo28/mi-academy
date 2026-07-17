# MI Academy — Current Architecture (Repository Audit)

> **Audit date:** 2026-07-17
> **Scope:** Foundation Sprint — Phase A
> **Status:** Complete

---

## 1. Executive summary

MI Academy is an offline-first educational game platform for children aged 5–12.
The repository today contains:

- A **FastAPI + PostgreSQL backend** (`apps/api/`) with a full relational schema,
  auth, and content models.
- **Python-based game-logic prototypes** (`packages/game_core/`, `packages/game-core/`)
  — server/experiment code, **not** the Flutter client engines described in the docs.
- **Rich documentation** (`docs/`) describing an intended Flutter + Flame client that
  **does not yet exist as code** (no `pubspec.yaml` anywhere).
- **Content datasets** (`content/vi/words.json`) and infra (`infrastructure/`).
- Assorted leftover scaffolding/junk files at the repo root (`_*.py`, `_*.txt`).

The **Foundation Sprint** introduces the missing Flutter client foundation:
a Melos-managed monorepo of shared `mi_game_*` packages, a versioned JSON level
schema + validator, and the Memory Cards vertical slice.

---

## 2. Current directory map (as audited)

```
mi-academy/
├── apps/
│   ├── api/                    FastAPI backend (Python 3.11)
│   │   ├── config.py           Pydantic Settings (DB, JWT, CORS, rate limits)
│   │   ├── database.py         Async SQLAlchemy engine + get_db
│   │   ├── dependencies.py     Auth: hashing, JWT, get_current_user, parent PIN
│   │   ├── main.py             FastAPI app + 9 routers
│   │   ├── requirements.txt    fastapi 0.115, sqlalchemy 2.0.35, pydantic 2.9.2 …
│   │   ├── models/__init__.py  13 ORM models
│   │   └── schemas/__init__.py ~35 Pydantic DTOs
│   └── mobile/                 EMPTY — Flutter app not yet created
├── packages/
│   ├── game_core/              Python game-logic prototype
│   ├── game-core/              Near-duplicate of game_core (accidental copy)
│   └── learning_core/          Empty
├── content/vi/words.json       88 Vietnamese vocabulary entries
├── docs/                       9 design docs (architecture, API, DB, UX …)
├── infrastructure/             docker-compose, migrations, seed, scripts
├── assets/ASSET_LICENSE_MANIFEST.json
├── PRD.md, README.md, pyproject.toml
└── _*.py / _*.txt              Leftover scaffolding (junk, safe to delete)
```

---

## 3. Backend (`apps/api/`) — present & healthy

| Concern            | Status | Notes                                                        |
|--------------------|--------|--------------------------------------------------------------|
| Web framework      | ✅     | FastAPI 0.115, async                                          |
| ORM / DB           | ✅     | SQLAlchemy 2.0 async + PostgreSQL 16                          |
| Auth               | ✅     | JWT access/refresh, bcrypt PIN hashing, role guard           |
| Models             | ✅     | 13 models incl. Game, Question, Attempt, Progress, ContentVersion |
| Migrations         | ✅     | `infrastructure/migrations/` + generator                     |
| Content versioning | ✅     | `ContentVersion` model + docs/api-specification sync section  |

The backend already models the **server-side** counterpart to what the client needs
(games, levels via `game_level`, questions, attempts, progress, content packages).

---

## 4. Existing Python "game" packages — clarification

`packages/game_core/` and `packages/game-core/` contain **Python** game-logic
prototypes (`GameEngineBase`, `GameInterface`, `math_race.py`, `scoring.py`,
`difficulty.py`). These are:

- **Not** the Flutter/Dart client engines the PRD & tech-architecture describe.
- **Duplicated** across two folders (`_` vs `-`) — an accidental copy.
- Useful as **reference** for scoring/difficulty rules on the server side.

**Decision:** Leave them for backend/reference use. The Flutter client engines are
built fresh under `packages/mi_game_*` (this sprint). See `GAME_PLATFORM_GAP_ANALYSIS.md`.

---

## 5. Client (`apps/mobile/`) — the gap

There is **no Flutter code** yet:

- No `pubspec.yaml`, no `lib/`, no Dart sources.
- `docs/tech-architecture.md` §4 fully specifies the intended structure — treated as
  the design target.

This sprint creates the **shared foundation** first (per blueprint §3: "Không bắt đầu
bằng việc xây game. Trước tiên cần xây một platform chung").

---

## 6. What the Foundation Sprint adds

```
packages/                         (new Dart/Flutter workspace, Melos-managed)
├── mi_game_core/                 lifecycle, state, save/restore, MiGame interface
├── mi_game_ui/                   shared widgets (header, pause, hint, feedback…)
├── mi_game_content/              JSON schema loading + validation
├── mi_game_audio/               voice/music/effects with volume groups + ducking
├── mi_game_progress/            attempt tracking, mastery, difficulty recommendation
├── mi_game_accessibility/       text scaling, SR labels, reduced motion, tap-alt
├── mi_game_testing/             shared test helpers, fakes, golden utilities
└── mi_blocks/                    MI Blocks command model (Robot Commands foundation)

apps/mobile/                      Flutter app shell + Memory Cards vertical slice
schemas/                          versioned JSON Schema for levels + content
melos.yaml, pubspec.yaml          workspace config
```

---

## 7. Toolchain observed on machine

`git, gh, docker, kubectl, gcloud, npm, pnpm, pip, go, curl, python, node, dotnet`.

**Flutter/Dart SDK not detected** in the CLI-tools list. Building & running the
Flutter workspace requires installing the Flutter SDK (see FOUNDATION_SPRINT_REPORT
"Known limitations"). All code is authored to be SDK-ready.

---

## 8. Immediate hygiene recommendations

- Remove root junk files: `_gen*.txt`, `_test*.txt`, `_s.txt`, `_sz.txt`,
  `_gen.ps1`, `_decode.py`, `_tmp_write.py`, `_gen_hex.txt`, `_build_sql.py`.
  (Keep `_gen_sql.py` only if still used to regenerate migrations, otherwise fold
  into `infrastructure/scripts/`.)
- Consolidate `packages/game-core/` into `packages/game_core/` (one canonical copy).
- Keep Python packages clearly separated (server) from Dart `mi_game_*` (client).
