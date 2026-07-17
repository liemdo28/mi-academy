# Secret Inventory — MI Academy

**Author:** Dev 6 (DevOps, Security & Reliability Lead)
**Date:** 2026-07-17
**Status:** Inventory of secrets the system needs. No real secret values are recorded here — this tracks *what exists and where it lives*, not the values themselves.

## 1. Secrets in use today (local/dev only)

| Secret | Purpose | Where set today | Production status |
|---|---|---|---|
| `SECRET_KEY` | JWT signing | `.env` / docker-compose env (dev placeholder) | Needs a unique, rotated value per environment; startup guard in `apps/api/config.py` refuses the placeholder when `APP_ENV=production` |
| `POSTGRES_PASSWORD` | Local Postgres auth | `infrastructure/docker/docker-compose.yml` (dev placeholder, plaintext) | Not applicable to a real deployment — production DB credentials must come from a secrets manager, never a checked-in compose file |

## 2. Secrets the system will need once real environments exist

None of these are provisioned yet — listed so the eventual secrets-manager setup has a complete checklist.

| Secret | Purpose | Owner | Rotation |
|---|---|---|---|
| `SECRET_KEY` (per env) | JWT signing | Dev 6 (infra) + Dev 1 (consumes) | Quarterly or on suspected compromise |
| Production `DATABASE_URL` credentials | DB auth | Dev 6 | Per secrets-manager rotation policy |
| `REDIS_URL` credentials (if Redis requires auth in prod) | Rate limiting, cache | Dev 6 | Per secrets-manager rotation policy |
| Android signing keystore + key password | Play Store release signing | Dev 6, restricted access | Not rotated (keystore must persist for app updates); back up securely, loss = cannot update the app |
| iOS distribution certificate + provisioning profile | App Store release signing | Dev 6, restricted access | Per Apple's certificate expiry (typically annual) |
| App Store Connect API key | Automated TestFlight/App Store upload | Dev 6 | Per Apple rotation guidance |
| Google Play service account JSON | Automated Play Store upload | Dev 6 | Per Google rotation guidance |
| Object storage credentials (content delivery) | Content package hosting | Dev 6 | Per secrets-manager rotation policy |
| Error-tracking DSN (GlitchTip, self-hosted per `docs/security.md`) | Error reporting | Dev 6 | Rotate on compromise only |
| AI provider API key(s) | Recommendation/content-assist services (Dev 5) | Dev 5 provisions request, Dev 6 stores/rotates | Per provider rotation guidance, plus cost-limit alerts |

## 3. Rules

- Secrets live in a secrets manager or CI secret store — never in a file tracked by git, never in a CI workflow YAML literal, never in a Docker image layer.
- No secret is shared across `development`/`staging`/`production` (see [ENVIRONMENT_STRATEGY.md](../infrastructure/ENVIRONMENT_STRATEGY.md) §4).
- Mobile builds never bundle admin or backend-signing secrets; the only mobile-side secret-adjacent value is the build-time `MI_ACADEMY_API_BASE_URL`, which is not sensitive (a URL, not a credential) but is still environment-locked per build channel.
- Any secret that appears in application logs is a bug — see the redaction requirement in the structured-logging work.

## 4. Current gap

There is no secrets manager or CI secret store configured yet because there is no deployed environment. This inventory exists so that setup is a checklist, not a scramble, once a hosting platform is chosen.
