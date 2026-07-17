# Audio Direction — MI Academy

- **Owner:** Dev 4 | **Date:** 2026-07-17 | **Status:** Normative
- Current state: 17 audio entries, all **silent placeholder WAVs** (see
  `apps/mobile/assets/audio/audio_manifest.json`). This doc defines what
  replaces them and how.

## 1. Three audio groups

**Voice** — MI narration, letter/word pronunciation, instructions, hints,
completion lines. **Effects** — tap, place, match, collect, correct, hint,
complete. **Music** — home, world map, in-game background, completion.

## 2. Voice direction

MI's voice: ấm, rõ, tốc độ vừa, không cao chói, không "hoạt hình quá mức",
không giọng quảng cáo, không la hét, không chê trách.

- **vi-VN (primary):** phát âm chuẩn, dấu rõ, không nuốt âm. Từ vựng học tập
  có **bản đọc chậm** (slow variant, ~0.75×tempo thu riêng — không time-stretch).
  Regional check với Dev 3 trước khi thu batch lớn.
- **en-US (default English locale):** một accent duy nhất trong toàn bộ content
  package. Không trộn accent.
- Mọi câu thoại đi qua Dev 3 copy review (§28 tone rules) **trước khi thu**.

Batch 1 script (~40 lines, with Dev 3): welcome, tutorial framing, hint
openers ("MI có một gợi ý…"), gentle retry ("Mình thử lại nhé"), completion
("Con đã hoàn thành nhiệm vụ"), goodbye.

## 3. Effects direction

Ngắn (≤ 400 ms), mềm, tần số trung — không chói, không âm "thất bại" gay gắt.
Incorrect KHÔNG có SFX riêng; chỉ có voice hint hoặc im lặng + motion nhẹ.
One family of timbres (cùng nhạc cụ nguồn) để app nghe thống nhất.

## 4. Music direction

Nhẹ, tempo 80–100 BPM, không percussion dồn dập, loop mượt (kiểm tra điểm nối),
tắt được trong settings, và **duck −12 dB khi MI nói** (side-chain trong
`mi_game_audio`). In-game music mặc định rất nhỏ (−24 LUFS relative) hoặc tắt
cho nhóm 5–7.

## 5. Technical standard

| Item | Standard |
|---|---|
| Format | OGG Vorbis (Android/Windows), AAC fallback iOS nếu cần — quyết định cùng Dev 2 theo `mi_game_audio` runtime |
| Sample rate | 44.1 kHz, mono cho voice/SFX, stereo cho music |
| Loudness | Voice −16 LUFS integrated; SFX peak −6 dBFS; Music −20 LUFS |
| True peak | ≤ −1 dBTP |
| Silence padding | ≤ 50 ms đầu/cuối |
| Naming | `<type>_<subject>_<variant>_<lang>_v01.ogg` (e.g. `voice_hint_first-letter_vi_v01.ogg`) |
| Budget | Voice clip ngắn ≤ 40 KB; music loop ≤ 500 KB; bundle per game, không preload chéo game |

## 6. Metadata (normative schema, §26)

```json
{
  "audioId": "vi-mi-hint-001",
  "language": "vi",
  "locale": "vi-VN",
  "type": "voice",
  "speaker": "mi_voice_01",
  "transcript": "Mình thử nhìn chữ đầu tiên nhé.",
  "durationMs": 2140,
  "normalized": true,
  "offlinePath": "assets/audio/vi/mi/hint_001.ogg",
  "reviewStatus": "approved"
}
```

Rules: no audio without transcript; no audio without license/consent record
(voice talent contract → Dev 3); `reviewStatus` must be `approved` before a
file ships. The existing `audio_manifest.json` migrates to this schema when the
first real recordings land (keep `placeholder: true` flag until then).

## 7. Accessibility

- Every voice line has a subtitle (transcript displayed on demand).
- Replay button on every listening interaction; slow-audio button where the
  content is a learning target.
- App fully usable muted: nothing is audio-only (pair with icon/text).

## 8. Production pipeline

SCRIPT (Dev 3 approved) → RECORD → EDIT/NORMALIZE (loudness spec §5) →
METADATA (§6) → LICENSE entry → INTEGRATE (`mi_game_audio`) → AUDIO QA
(device speaker + headphone pass, ducking check, diacritics pronunciation check).
