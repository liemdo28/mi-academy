# MI Academy — Open Source Inventory (Game Algorithms & Reference Code)

> **Version:** 1.0.0
> **Date:** 2026-07-17
> **Owner:** Dev 3

---

## Purpose

Document open-source code referenced for algorithmic inspiration. This is
**not** a dependency list (see `OPEN_SOURCE_AUDIT.md` for deps). This
documents code we looked at for patterns and decided NOT to integrate directly.

---

## Algorithmic references

### 1. Card matching / memory game algorithms

| Project | License | Mechanic | Decision |
|---------|---------|----------|----------|
| GCompris memory activity | GPL-3 | Grid memory match | REFERENCE_ONLY — studied grid layout + match logic |

### 2. Pathfinding / maze algorithms

| Project | License | Mechanic | Decision |
|---------|---------|----------|----------|
| Flame maze examples | MIT | Grid navigation | APPROVED_FOR_REFERENCE — studied BFS/pathfinding |
| Pathfinding A* (various) | MIT | Robot pathfinding | APPROVED_FOR_REFERENCE — used as conceptual model |

### 3. Block programming / interpreter

| Project | License | Mechanic | Decision |
|---------|---------|----------|----------|
| Blockly | Apache-2 | Block editor (web) | APPROVED_WITH_ADAPTATION — studied data model, not integrated |
| Blockly Games Maze | Apache-2 | Maze puzzle | REFERENCE_ONLY — studied level progression |

### 4. Math question generation

| Project | License | Mechanic | Decision |
|---------|---------|----------|----------|
| Khan Academy Kids | N/A (commercial) | Math drills | REFERENCE_ONLY — studied distractor generation patterns |

### 5. Tangram / shape construction

| Project | License | Mechanic | Decision |
|---------|---------|----------|----------|
| Tangram.js (various) | MIT | Tangram puzzles | APPROVED_FOR_REFERENCE — studied constraint solving |

### 6. Currency / supermarket simulation

| Project | License | Mechanic | Decision |
|---------|---------|----------|----------|
| GCompris money activities | GPL-3 | Coin/notes exercises | REFERENCE_ONLY — studied currency exercise design |

### 7. Level validation

| Project | License | Mechanic | Decision |
|---------|---------|----------|----------|
| JSON Schema validators | MIT/BSD | Schema validation | APPROVED_FOR_INTEGRATION — jsonschema Python package |

---

## Rules for future references

1. Every referenced repo must have: name, URL, license, commit hash, mechanic, decision
2. Decision must be one of: APPROVED_FOR_INTEGRATION, APPROVED_FOR_REFERENCE, REQUIRES_LEGAL_REVIEW, REJECTED
3. No GPL code may be copied into MI Academy source
4. Algorithmic ideas can be independently implemented
5. Attribution in NOTICES if algorithm is recognizable from source
