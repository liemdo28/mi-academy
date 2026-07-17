# MI Academy — Platform Security Review

**Date:** 2026-07-17
**Owner:** Platform & Learning Lead
**Status:** Initial Review — Pre-MVP

---

## 1. Child Privacy Compliance

### 1.1 Data Minimization

| Data Point | Collected? | Required? | Notes |
|---|---|---|---|
| Child full name | ❌ No | N/A | Only nickname (max 50 chars) |
| Child email | ❌ No | N/A | Not requested |
| Child phone | ❌ No | N/A | Not requested |
| Child address | ❌ No | N/A | Not requested |
| Child GPS | ❌ No | N/A | No location permissions |
| Child photo | ❌ No | N/A | Only avatar reference string |
| Child birth year | ⚠️ Optional | No | Used for age group derivation |
| Child grade level | ⚠️ Optional | No | Used for content selection |

### 1.2 Child Mode Isolation

| Requirement | Status |
|---|---|
| No parent email visible | ✅ Design enforced |
| No parent password visible | ✅ Design enforced |
| No parent name visible | ✅ Design enforced |
| No admin features in child mode | ✅ Separate route tree |
| No external links | ⚠️ Link blocker not implemented |
| No social/chat | ✅ Not present |
| No public profiles | ✅ Not present |

---

## 2. Authentication & Authorization

### 2.1 Password Security

| Feature | Status |
|---|---|
| Password hashing | ✅ bcrypt (12 rounds) |
| PIN hashing | ✅ bcrypt (12 rounds) |
| No plain-text passwords | ✅ Verified in code |
| Password strength validation | ⚠️ Min 8 chars enforced in schema |
| Account lockout | ❌ Not implemented |

### 2.2 JWT Tokens

| Feature | Status |
|---|---|
| Access token | ✅ 30 min expiry |
| Refresh token | ✅ 30 day expiry |
| Token rotation on refresh | ✅ New refresh token issued |
| Token type claim | ✅ "access" or "refresh" |
| Token blocklist | ❌ Not implemented (stateless) |
| Parent session token | ✅ Short-lived, for PIN verification |

### 2.3 Authorization

| Feature | Status |
|---|---|
| Parent can only see own children | ✅ ForeignKey enforced |
| Child progress restricted to parent | ⚠️ Endpoint needs auth check |
| Admin routes protected | ⚠️ Admin auth needs implementation |
| API key for mobile app | ❌ Not implemented |

---

## 3. Network Security

| Feature | Status |
|---|---|
| HTTPS | ⚠️ Not enforced (dev) |
| CORS restriction | ✅ Fixed from `["*"]` to `[]` |
| CORS configurable via env | ✅ |
| Rate limiting (sync) | ⚠️ Config defined, not enforced |
| Rate limiting (auth) | ⚠️ Config defined, not enforced |
| Request body size limit | ⚠️ Not configured |
| Content-Type validation | ✅ FastAPI default |

---

## 4. Data Security

### 4.1 Secrets Management

| Item | Status |
|---|---|
| SECRET_KEY in env | ✅ Config via env var |
| Default placeholder | ⚠️ Still uses "CHANGE_ME..." placeholder |
| `.env` excluded from git | ⚠️ `.env.example` exists; `.env` should be in `.gitignore` |
| Database credentials | ✅ In Docker env vars |

### 4.2 Sensitive Data

| Data | Protection |
|---|---|
| Passwords | ✅ bcrypt hashed, never logged |
| PIN | ✅ bcrypt hashed |
| JWT tokens | ✅ Not stored in API logs |
| Child data | ✅ No PII collected |
| Parent email | ⚠️ Could appear in logs (needs audit) |
| API responses | ⚠️ Stack traces may leak in debug mode |

### 4.3 Content Validation

| Feature | Status |
|---|---|
| JSON Schema validation | ✅ Schemas defined |
| Input length limits | ✅ Pydantic Field validators |
| SQL injection | ✅ SQLAlchemy parameterized queries |
| XSS prevention | ⚠️ JSON content stored directly (mobile app renders) |
| Content size limits | ⚠️ No max size on `content_json` |

---

## 5. Advertising & Tracking

| Requirement | Status |
|---|---|
| No advertising SDKs | ✅ No ad libraries found |
| No analytics SDKs (Firebase, etc.) | ✅ None present |
| No external tracking | ✅ No external calls |
| No Google Analytics | ✅ Not present |
| No Facebook SDK | ✅ Not present |
| No crash reporting | ⚠️ None configured |

---

## 6. Permissions & Access

| Permission | Used? | Justified? |
|---|---|---|
| Internet | ✅ | Required for sync |
| Storage | ✅ | Hive local storage |
| Camera | ❌ | Not used |
| GPS/Location | ❌ | Not used |
| Contacts | ❌ | Not used |
| SMS | ❌ | Not used |
| Bluetooth | ❌ | Not used |
| Microphone | ❌ | Not used (future: sound_match game) |
| Biometric | ⚠️ Future | For parent PIN verification |

---

## 7. GDPR / Data Rights

| Right | Implementation |
|---|---|
| Right to access | ⚠️ Privacy-safe JSON export implemented locally; deployed proof pending |
| Right to deletion | ⚠️ Cascade delete implemented locally; deployed proof pending |
| Right to data portability | ⚠️ JSON export schema implemented locally; deployed proof pending |
| Consent mechanism | ⚠️ T&C acceptance at registration needed |
| Data retention | ⚠️ No retention policy defined |
| Data breach notification | ⚠️ No breach detection |

---

## 8. Third-Party Libraries

| Library | Purpose | Risk |
|---|---|---|
| FastAPI | Web framework | Low |
| SQLAlchemy | ORM | Low |
| Pydantic | Validation | Low |
| bcrypt | Password hashing | Low |
| python-jose | JWT tokens | Low |
| Flutter | Mobile framework | Low |
| Riverpod | State management | Low |
| Hive | Local storage | Low |
| Dio | HTTP client | Low |
| go_router | Routing | Low |
| flutter_secure_storage | Token storage | Low |
| local_auth | Biometric auth | Low |

**No advertising SDKs. No analytics SDKs. No tracking SDKs.**

---

## 9. CI/CD Security

| Feature | Status |
|---|---|
| Secrets in CI | ⚠️ Uses GitHub Actions secrets |
| Dependency audit | ⚠️ No automated dependency scanning |
| Code scanning | ⚠️ No SAST configured |
| Container scanning | ⚠️ No Docker image scanning |
| Secret scanning | ⚠️ No secret detection in CI |

---

## 10. Critical Security Issues (Prioritized)

### 🔴 Critical

| Issue | Location | Action |
|---|---|---|
| SECRET_KEY placeholder | `apps/api/config.py` | Require 64+ char key in production |
| No external link blocker | Child mode | Implement link interceptor |

### 🟡 Medium

| Issue | Location | Action |
|---|---|---|
| Rate limiting not enforced | API endpoints | Implement `slowapi` or custom |
| No JWT blocklist | Auth system | Implement Redis blocklist for logout |
| No dependency scanning | CI pipeline | Add `dependabot` or `pip-audit` |
| No audit log | Database | Add `audit_log` table |
| Data export not deployed-verified | Parent API | Verify JSON export endpoint against deployed API |
| Data deletion not deployed-verified | Parent API | Verify cascade delete against deployed API |

### 🟢 Low

| Issue | Location | Action |
|---|---|---|
| No account lockout | Auth | Add brute-force protection |
| No request body size limit | API | Add max request size |
| No content size limit | Lesson content_json | Add max JSON size |

---

## 11. Recommendations

### Before MVP Release

1. Generate and require a 64+ character `SECRET_KEY`
2. Implement external link blocker in child mode
3. Enforce rate limiting on auth endpoints
4. Verify data export endpoint in deployed API
5. Verify data deletion cascade in deployed API
6. Add consent mechanism at registration
7. Implement content size limits
8. Add CORS origin configuration for production
9. Add API key authentication for mobile app

### Before Public Launch

10. Add JWT blocklist (Redis)
11. Add audit logging
12. Add dependency scanning (Dependabot)
13. Add SAST scanning (CodeQL)
14. Add automated security tests
15. Add data retention policy
16. Implement breach detection and notification
17. Conduct penetration test

---

## 12. Security Checklist

- [x] No advertising SDKs
- [x] No external tracking
- [x] No GPS
- [x] No contacts
- [x] No public profile
- [x] No child-to-child chat
- [x] No external links in child mode (design)
- [x] No parent credentials in game
- [x] No sensitive data logging (code reviewed)
- [x] Secrets out of code (use .env)
- [ ] Data export workflow
- [ ] Data deletion workflow
- [ ] External link blocker in child mode
- [ ] Rate limiting enforced
- [ ] JWT blocklist

---

*End of Platform Security Review*
