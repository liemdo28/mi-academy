# Child Usability Risk Report — MI Academy

- **Owner:** Dev 4
- **Date:** 2026-07-17
- **Audience:** all devs; Dev 3 for child-safety sign-off

Risks are ranked by (impact on a 5–7-year-old non-reader) × (likelihood).

## R1 — Dead buttons in Child Home tab bar — **High**
"Sao" and "Huy hiệu" tabs do nothing (`child_home_screen.dart:97-102`).
A child who taps and gets no response learns the app is unreliable and may
start rage-tapping everywhere. **Fix:** remove tabs until features exist;
never ship a child-visible control without behavior.

## R2 — Parent area one tap from child space — **High**
Settings icon in the app bar and "Phụ huynh" tab both push `/parent`. Even
with a PIN screen behind it, a child repeatedly hitting a PIN pad is a
frustration loop, and the affordance invites tapping. **Fix:** single discreet
parent-gate entry (small corner icon, no colorful styling), gate interaction
(e.g., hold 3s or "tap the number shown as a word") before the PIN pad. Verify
route guard with Dev 1.

## R3 — No voice guidance while target users cannot read — **Critical**
Every instruction on Child Home and in tutorials is text-only; all audio files
are silent placeholders. A 5-year-old cannot use the app unassisted.
**Fix:** voice-first instruction plan in `docs/audio/AUDIO_DIRECTION.md`;
every child-facing screen spec now carries an `Audio` section (§39).

## R4 — Emoji-as-icon — **Medium**
Emoji vary by device vendor (a Samsung 🧠 ≠ Pixel 🧠), can't be recolored for
high contrast, and some render as tofu on older Android. **Fix:** owned SVG
icon set (see `DESIGN_SYSTEM_AUDIT.md` §8, icon plan in `MI_DESIGN_SYSTEM.md`).

## R5 — Color-only feedback in games — **Medium**
Success/error rely primarily on color tint (green/orange). Must pair icon +
text/audio + motion per §7. Coordinate with Dev 2; add to visual QA checklist.

## R6 — Pull-to-refresh as hidden mechanic — **Low**
Children won't discover it and don't need it. **Fix:** auto-refresh on focus;
keep the gesture for parents only.

## R7 — Competing choices on first screen — **Medium**
Plan list + 5 subject cards + 4 tabs ≈ 10+ choices on first open; spec limit
for 5–7 is 3–4 primary options. **Fix:** Child Home v2 wireframe leads with one
`Tiếp tục học` CTA.

## R8 — Text scale fragility — **Medium**
Fixed-height buttons/cards will clip Vietnamese descenders and diacritics at
large text sizes (font not even bundled — see audit). **Fix:** bundle Nunito
(vi subset), min-height instead of fixed height, large-text QA gate.

## R9 — Error copy tone unverified — **Medium**
Error states exist but copy has not been through the §28 review ("no 'Sai',
'Thua rồi'…"). **Fix:** copy inventory with Dev 3 before Wave 1 exit.

## R10 — No exit/pause consistency audit yet — **Low**
`mi_game_ui` has ExitConfirmation and PauseButton; placement vs the §9 rule
("exit never adjacent to continue") must be verified per game during Wave 1
visual QA.

## Test protocol hooks (with Dev 3, §30)
Each risk above maps to an observation item in the user-testing protocol:
time-to-first-action (R7), mis-taps (R1/R2/R10), audio reliance (R3),
hint comprehension (R5). No child data collected without consent flow.
