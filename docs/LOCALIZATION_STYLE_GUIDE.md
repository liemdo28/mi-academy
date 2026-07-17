# MI Academy — Localization Style Guide

> **Version:** 1.0.0
> **Date:** 2026-07-17

---

## 1. Principles

- Every user-facing string has a stable key (no hardcoded text in game code).
- Vietnamese (vi) is the primary language — English (en) is secondary.
- Content must be age-appropriate for 5–12 year olds.
- MI's voice is positive, encouraging, and never pressuring.

---

## 2. MI's voice — Approved responses

### Correct answer
| Vietnamese | English |
|-----------|---------|
| "Tuyệt vời!" | "Wonderful!" |
| "Đúng rồi!" | "That's right!" |
| "Con giỏi quá!" | "Great job!" |
| "Chính xác!" | "Exactly!" |
| "Hay quá!" | "Awesome!" |

### Incorrect answer
| Vietnamese | English |
|-----------|---------|
| "Thử lại nhé!" | "Try again!" |
| "Gần đúng rồi, mình thử lại nhé." | "Almost right, let's try again." |
| "Con đã tìm được một phần." | "You found part of it." |
| "MI sẽ cho con một gợi ý." | "MI has a hint for you." |
| "Không sao, mình cùng thử lại." | "No worries, let's try together." |

### Hint
| Vietnamese | English |
|-----------|---------|
| "Nhìn kỹ nhé!" | "Look closely!" |
| "MI gợi ý cho con:" | "MI has a hint:" |
| "Thử nhìn vào đây." | "Try looking here." |

### Completion
| Vietnamese | English |
|-----------|---------|
| "Chúc mừng con!" | "Congratulations!" |
| "Con đã hoàn thành!" | "You did it!" |
| "Tuyệt vời, con đã học thêm điều mới." | "Wonderful, you learned something new!" |

---

## 3. Prohibited phrases

| ❌ Never use | Reason |
|-------------|--------|
| "Sai rồi!" / "Wrong!" | Too harsh |
| "Con thua" / "You lose" | No losing condition |
| "Quá chậm" / "Too slow" | No time pressure |
| "Con phải cố hơn" / "Try harder" | Pressuring |
| "Mất chuỗi ngày học" / "Lost your streak" | No streak punishment |
| "Bạn của con giỏi hơn" | No comparison |

---

## 4. Vietnamese-specific rules

### Tone marks
- Always use correct Vietnamese diacritics: ă, â, ê, ô, ơ, ư + 6 tones
- Never strip tone marks in display

### Grapheme handling
- Word Builder must handle Vietnamese syllable boundaries correctly
- "Con mèo" = 2 syllables, NOT 7 characters split naively
- Use Unicode grapheme cluster segmentation, NOT String.length

### Currency
- Vietnamese Dong: "₫" symbol AFTER number: "10.000₫"
- Thousands separator: "." (period)
- No decimal places for VND

### Date format
- dd/MM/yyyy (day first)

---

## 5. String key naming convention

```
{game}_{context}_{element}_{variant}

Examples:
memory_cards_level1_prompt_vi
word_builder_hint_1_en
math_race_correct_feedback_vi
robot_commands_error_blocked_en
```

---

## 6. Pluralization

Flutter's `intl` package handles pluralization:
```
{count, plural, =0{No items} =1{1 item} other{{count} items}}
```

Vietnamese does not have grammatical plural forms — use the same word:
- "1 thẻ" / "5 thẻ" (no change)

---

## 7. Variable interpolation

Use named variables for safety:
```
"Con đã ghép được {count} cặp!" / "You matched {count} pairs!"
```

Never use positional `{0}` — named variables are clearer and less error-prone.

---

## 8. Text length limits

| Context | Max characters |
|---------|---------------|
| Button label | 20 |
| Card content | 15 |
| Prompt text | 100 |
| Hint text | 80 |
| Feedback message | 60 |
| Error message | 80 |
| Tutorial step | 150 |
