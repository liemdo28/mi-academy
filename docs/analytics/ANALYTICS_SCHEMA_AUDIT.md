# Analytics Schema Audit — MI Academy

> **Audit date:** 2026-07-17
> **Owner:** Adaptive Learning AI & Analytics Lead

---

## 1. Current analytics capability

| Event type | Source | Tracked | Schema-defined |
|-----------|--------|---------|---------------|
| `session_started` | `game_session.started_at` | ✅ | ❌ |
| `session_completed` | `game_session.finished=true` | ✅ | ❌ |
| `attempt_submitted` | `attempt` rows | ✅ | ❌ |
| `level_abandoned` | implicit | ⚠️ | ❌ |
| `hint_requested` | — | ❌ | ❌ |
| `snapshot_saved` | — | ❌ | ❌ |
| `snapshot_restored` | — | ❌ | ❌ |
| `recommendation_served` | — | ❌ | ❌ |
| `recommendation_accepted` | — | ❌ | ❌ |
| `content_error` | — | ❌ | ❌ |
| `technical_error` | `error_log` table | ⚠️ | ❌ |

---

## 2. Required analytics event schema

### 2.1 Base event structure

```json
{
  "eventId": "evt-{uuid}",
  "eventType": "game_completed",
  "anonymousProfileKey": "local-profile-key",
  "timestamp": "2026-07-17T09:00:00Z",
  "schemaVersion": 1,
  "gameId": "word_builder",
  "levelId": "word_builder_003",
  "skillIds": ["letters.word_building"],
  "metrics": {
    "attemptCount": 3,
    "correctCount": 2,
    "hintCount": 1,
    "durationSeconds": 92,
    "starsEarned": 2
  },
  "metadata": {}
}
```

### 2.2 Event type specifications

| Event | Required fields | Optional fields |
|-------|----------------|----------------|
| `session_started` | childId, gameId, levelId, timestamp | accessibilityMode |
| `session_completed` | childId, gameId, levelId, timestamp, attemptCount, correctCount, hintCount, durationSeconds | starsEarned, completed |
| `hint_requested` | childId, gameId, levelId, timestamp, hintLevel | skillId |
| `level_abandoned` | childId, gameId, levelId, timestamp, attemptCount | reason |
| `snapshot_saved` | childId, gameId, levelId, timestamp | stateSize |
| `snapshot_restored` | childId, gameId, levelId, timestamp, snapshotAge | — |
| `recommendation_served` | childId, timestamp, recommendationType, targetId, reasonCodes, engineVersion | confidence, score |
| `recommendation_accepted` | childId, timestamp, recommendationId | latencyMs |
| `recommendation_rejected` | childId, timestamp, recommendationId, rejectionReason | alternativeChosen |
| `content_error` | childId, gameId, levelId, timestamp, errorCode | stackHash |
| `technical_error` | appVersion, platform, errorType, stackHash | count |

### 2.3 Prohibited in analytics events

```
❌ GPS coordinates
❌ Contact list
❌ Advertising ID
❌ Audio/video recording
❌ Keystroke outside game context
❌ Child display name
❌ Parent email or credentials
❌ Device serial number
❌ Cross-app tracking identifiers
```

---

## 3. Analytics aggregation levels

### 3.1 Individual child level
- Own mastery state
- Own recommendation history
- Own session history
- Own struggle signals

### 3.2 Anonymized aggregate level
- Level completion rate (≥30 samples, no individual identification)
- Level average hint rate
- Level average duration
- Error pattern frequency per skill
- Content quality indicators

### 3.3 Platform level
- Total active children per day
- Most used games
- Feature adoption rates
- Error rate per app version

---

## 4. Observability requirements

| Metric | Target | Alert threshold |
|--------|--------|----------------|
| Recommendation latency (p95) | < 100ms | > 500ms |
| Recommendation failure rate | < 0.1% | > 1% |
| Fallback rate | < 5% | > 20% |
| Invalid output rate | < 0.5% | > 5% |
| Content validation failure | < 2% | > 10% |
| Parent insight failure | < 1% | > 5% |

---

## 5. Privacy architecture requirements

- Analytics events MUST use `anonymousProfileKey` (pseudonymous, not child UUID)
- No raw PII in log lines
- Event data retention: 90 days rolling window for individual, aggregate indefinitely
- Deletion: when child profile deleted, anonymize all associated events
- Cross-device: no linking without explicit consent
