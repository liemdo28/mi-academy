# Motion System — MI Academy

- **Owner:** Dev 4 | **Date:** 2026-07-17 | **Status:** Normative

## 1. Principles

Motion explains, never decorates for its own sake. Short, legible, calm.
Nothing loops aggressively, blocks input, or flashes. Every motion has a
reduced-motion variant — this is a Definition-of-Done gate, not an option.

## 2. Tokens

| Token | Duration | Easing | Use |
|---|---|---|---|
| `motion.instant` | 0 ms | — | Reduced-motion substitutions, state swaps |
| `motion.fast` | 120 ms | easeOut | Press feedback, ripples, toggles |
| `motion.normal` | 240 ms | easeInOut | Page transitions, card entrance, overlay fade |
| `motion.slow` | 400 ms | easeInOut | World-map focus shift, sheet slide |
| `motion.celebration` | 1200–3000 ms | custom, **skippable** | Level completion only |

Stagger: list entrances 40 ms/item, max 6 items animated, rest appear instantly.

## 3. Reduced-motion substitution table (normative)

| Full motion | Reduced-motion variant |
|---|---|
| Card flip 3D (Memory Cards) | Cross-fade front/back, 120 ms |
| Character/vehicle movement (Math Race) | Static progress bar fills |
| Celebration confetti + MI dance | Static star burst icon + fade-in text |
| Camera pan on world map | Immediate position change |
| MI idle breathing/blinking | Single still frame |
| Sparkle on correct | Icon appears (no particles) |
| Screen transitions | 120 ms fade only |

Trigger: `MediaQuery.disableAnimations` **OR** in-app accessibility setting
(parent-controlled). Helper `MiMotion.of(context)` in `design_system` resolves
tokens to zero/fade variants centrally — widgets never check the flag themselves.

## 4. Feedback motion rules (child-safe)

- **Correct:** small scale-pop (1.0→1.06→1.0, `motion.fast`) + sparkle near the
  object (not full-screen) + MI happy. Total ≤ 800 ms.
- **Incorrect:** NO shake, NO flash, NO big X. The chosen item settles back
  (`motion.fast`), MI switches to thinking/hinting. Nothing punitive.
- **Completion:** 1–3 s celebration, tap-anywhere to skip, then static summary.
- No flashing above 3 Hz anywhere (photosensitivity).
- Idle attractors (e.g., pulsing CTA) max 2 pulses then rest ≥ 8 s.

## 5. MI character animation budget

Rive, single artboard, face-state machine (see `MI_CHARACTER_GUIDE.md`).
- Idle: blink every 4–7 s, 2 px hover bob. Never large looping gestures.
- Reaction states auto-return to neutral ≤ 1.5 s.
- File budget: MI master .riv ≤ 300 KB; UI micro-animations ≤ 50 KB each.

## 6. Component motion catalog

| Component | Enter | Exit | Press |
|---|---|---|---|
| Dialog/CompletionOverlay | fade+scale 0.96→1, normal | fade, fast | — |
| BottomSheet | slide-up, slow | slide-down, normal | — |
| Toast | slide+fade top, normal, auto-dismiss 3 s | fade, fast | — |
| Buttons | — | — | scale 0.97, fast |
| ProgressDots | dot fill, fast | — | — |
| Letter tile (drag) | lift shadow, fast | drop settle, fast | scale 1.05 |

## 7. QA hooks

Visual QA checklist (`docs/visual-qa/`) tests every screen in reduced-motion
mode; any full-motion-only behavior is a release blocker.
