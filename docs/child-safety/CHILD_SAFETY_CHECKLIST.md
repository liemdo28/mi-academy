# MI Academy — Child Safety Checklist

> **Version:** 1.0.0
> **Date:** 2026-07-17
> **Required score:** 10/10 per game before release

---

## Checklist

Each game and screen MUST pass ALL items. Any failure = P0 release blocker.

### 1. No advertising
- [ ] No ads displayed anywhere
- [ ] No ad SDK in dependencies
- [ ] No ad-related analytics events
- [ ] No banner, interstitial, or rewarded ads

### 2. No upsell / IAP
- [ ] No purchase prompts
- [ ] No premium content gates
- [ ] No subscription notices
- [ ] No "unlock more" messages

### 3. No external links
- [ ] No URLs in child-facing screens
- [ ] No "visit website" buttons
- [ ] No social media icons
- [ ] No email links
- [ ] No outbound HTTP calls from game code

### 4. No chat / social features
- [ ] No chat interface
- [ ] No social feed
- [ ] No message sending
- [ ] No friend requests
- [ ] No public leaderboards

### 5. No comparison with other children
- [ ] No "other kids scored..."
- [ ] No public rankings
- [ ] No peer pressure messaging
- [ ] No "your friend is ahead"

### 6. No pressure mechanics
- [ ] No mandatory timers (optional visual timer OK)
- [ ] No streak punishment ("you lost your streak!")
- [ ] No loss of rewards for taking breaks
- [ ] No "come back tomorrow or lose progress"
- [ ] No countdown pressure on answers

### 7. No harmful feedback
- [ ] No red "X" or angry faces on wrong answers
- [ ] No loud failure sounds
- [ ] No "sai rồi!" / "wrong!" messaging
- [ ] No penalty for wrong answers
- [ ] Gentle retry messaging: "Thử lại nhé!", "Gần đúng rồi"

### 8. No excessive data collection
- [ ] No GPS/location
- [ ] No contact access
- [ ] No camera access
- [ ] No microphone access (except explicit voice activity)
- [ ] No advertising identifier
- [ ] No email or phone number collection
- [ ] No biometric data

### 9. Parent gate
- [ ] All settings behind PIN
- [ ] Data deletion accessible to parent
- [ ] No child can modify parent settings
- [ ] Parent can review all content

### 10. Content safety
- [ ] No violence
- [ ] No scary imagery
- [ ] No gender stereotyping
- [ ] No cultural insensitivity
- [ ] Age-appropriate vocabulary
- [ ] Positive, encouraging tone throughout

---

## Scoring

Each item = 1 point. Maximum = 10 categories.
**Required for release: 10/10.**
Any 0 on any category = P0 blocker.

---

## Review process

1. Automated: Privacy tests in CI (`tools/game_network_audit.py` for no outbound game-code calls, `tools/child_safety_audit.py` for prohibited APIs/dependencies, `tools/content_safety_audit.py` for authored child-facing text, `tools/mobile_platform_privacy_audit.py` for platform/dependency privacy surfaces, and `tools/child_safety_signoff.py` for per-game pre-signoff evidence)
2. Manual: QA reviewer completes this checklist per game on a real device or emulator
3. Sign-off: Release cannot proceed without the automated pre-signoff report and the completed human checklist attached to the release PR
