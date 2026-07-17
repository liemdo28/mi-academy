"""MI Academy shared contracts — single source of truth for all contracts."""
from __future__ import annotations

# ─── Contract Registry ───────────────────────────────────────────────────────
# All contracts must be registered here with their current version.

CONTRACT_REGISTRY: dict[str, ContractDef] = {}

def register(
    contract_id: str,
    schema_version: int,
    semantic_version: str,
    owner: str,
    compatibility: str,  # patch | backward | potentially-breaking | breaking
    description: str,
    deprecated_fields: list[str] | None = None,
    migration_path: str | None = None,
    deprecation_date: str | None = None,
    minimum_app_version: str = "1.0.0",
) -> callable:
    """Decorator to register a contract definition."""
    def decorator(cls: type) -> type:
        CONTRACT_REGISTRY[contract_id] = ContractDef(
            contract_id=contract_id,
            schema_version=schema_version,
            semantic_version=semantic_version,
            owner=owner,
            compatibility=compatibility,
            description=description,
            deprecated_fields=deprecated_fields or [],
            migration_path=migration_path,
            deprecation_date=deprecation_date,
            minimum_app_version=minimum_app_version,
        )
        return cls
    return decorator


class ContractDef:
    """Immutable contract definition."""
    __slots__ = (
        "contract_id", "schema_version", "semantic_version", "owner",
        "compatibility", "description", "deprecated_fields",
        "migration_path", "deprecation_date", "minimum_app_version",
    )

    def __init__(
        self,
        contract_id: str,
        schema_version: int,
        semantic_version: str,
        owner: str,
        compatibility: str,
        description: str,
        deprecated_fields: list[str],
        migration_path: str | None,
        deprecation_date: str | None,
        minimum_app_version: str,
    ):
        self.contract_id = contract_id
        self.schema_version = schema_version
        self.semantic_version = semantic_version
        self.owner = owner
        self.compatibility = compatibility
        self.description = description
        self.deprecated_fields = deprecated_fields
        self.migration_path = migration_path
        self.deprecation_date = deprecation_date
        self.minimum_app_version = minimum_app_version

    def to_dict(self) -> dict:
        return {s: getattr(self, s) for s in self.__slots__}


# ─── Game Contracts ──────────────────────────────────────────────────────────

@register(
    contract_id="mi.game.launch",
    schema_version=1,
    semantic_version="1.0.0",
    owner="dev-2",
    compatibility="backward",
    description="Platform-to-game launch request with full context.",
)
class MiGameLaunchRequest:
    """Source: shared_models.dart MiGameLaunchRequest (v1)."""
    SCHEMA_VERSION = 1
    REQUIRED_FIELDS = frozenset([
        "schemaVersion", "childProfileId", "gameId", "levelId",
        "language", "ageGroup", "accessibility", "audioPreferences", "levelContent",
    ])
    FORBIDDEN_FIELDS = frozenset([
        "accessToken", "refreshToken", "password", "parentEmail",
        "parentId", "pin", "authToken",
    ])


@register(
    contract_id="mi.game.result",
    schema_version=1,
    semantic_version="1.0.0",
    owner="dev-2",
    compatibility="backward",
    description="Game-to-platform result with mastery and skill evidence.",
)
class MiGameResult:
    """Source: shared_models.dart MiGameResult (v1)."""
    SCHEMA_VERSION = 1
    REQUIRED_FIELDS = frozenset([
        "schemaVersion", "attemptId", "childProfileId", "gameId", "levelId",
        "startedAt", "completedAt", "attemptCount", "correctCount",
        "incorrectCount", "hintCount", "durationSeconds", "completed",
        "masteryEvidence", "skillEvidence",
    ])
    FORBIDDEN_FIELDS = frozenset([
        "accessToken", "refreshToken", "password", "parentEmail",
        "parentId", "pin",
    ])
    MASTERY_EVIDENCE_RANGE = (0.0, 1.0)


@register(
    contract_id="mi.game.snapshot",
    schema_version=1,
    semantic_version="1.0.0",
    owner="dev-2",
    compatibility="backward",
    description="In-progress game state for save/resume across sessions.",
    migration_path="SnapshotMigrator.migrate",
)
class MiGameSnapshot:
    """Source: shared_models.dart MiGameSnapshot (v1)."""
    SCHEMA_VERSION = 1
    REQUIRED_FIELDS = frozenset([
        "schemaVersion", "gameId", "levelId", "childProfileId", "savedAt", "state",
    ])
    FORBIDDEN_FIELDS = frozenset([
        "accessToken", "refreshToken", "password", "parentEmail",
    ])


# ─── Progress Contracts ────────────────────────────────────────────────────────

@register(
    contract_id="mi.progress",
    schema_version=1,
    semantic_version="1.0.0",
    owner="dev-1",
    compatibility="backward",
    description="Lesson progress and mastery score.",
)
class LessonProgress:
    """Source: shared_models.dart LessonProgress (v1)."""
    SCHEMA_VERSION = 1
    STATUS_VALUES = frozenset(["notStarted", "learning", "completed", "needsPractice", "mastered"])
    STATUS_PYTHON_MAP = {
        "not_started": "notStarted",
        "learning": "learning",
        "completed": "completed",
        "needs_practice": "needsPractice",
        "mastered": "mastered",
    }


@register(
    contract_id="mi.sync.attempt",
    schema_version=1,
    semantic_version="1.0.0",
    owner="dev-1",
    compatibility="backward",
    description="Game attempt synced from client to backend.",
)
class SyncAttemptItem:
    """Source: apps/api/schemas/sync.py SyncAttemptItem (v1)."""
    SCHEMA_VERSION = 1
    REQUIRED_FIELDS = frozenset([
        "id", "childId", "lessonId", "gameId", "questionId",
        "answerJson", "isCorrect", "responseTimeMs", "hintCount", "createdAt",
    ])


@register(
    contract_id="mi.sync.progress",
    schema_version=1,
    semantic_version="1.0.0",
    owner="dev-1",
    compatibility="backward",
    description="Progress synced from client to backend.",
)
class SyncProgressItem:
    """Source: apps/api/schemas/sync.py SyncProgressItem (v1)."""
    SCHEMA_VERSION = 1


# ─── Content Contracts ────────────────────────────────────────────────────────

@register(
    contract_id="mi.content.lesson",
    schema_version=1,
    semantic_version="1.0.0",
    owner="dev-3",
    compatibility="backward",
    description="Lesson content package definition.",
)
class LessonContent:
    """Source: content/schemas/lesson.schema.json (v1)."""
    SCHEMA_VERSION = 1


@register(
    contract_id="mi.content.level",
    schema_version=1,
    semantic_version="1.0.0",
    owner="dev-3",
    compatibility="backward",
    description="Game level content definition.",
)
class LevelContent:
    """Source: schemas/level.schema.json (v1)."""
    SCHEMA_VERSION = 1


# ─── Adaptive Contracts ───────────────────────────────────────────────────────

@register(
    contract_id="mi.adaptive.evidence",
    schema_version=1,
    semantic_version="1.0.0",
    owner="dev-5",
    compatibility="backward",
    description="Skill mastery evidence from game results.",
)
class SkillEvidence:
    """Evidence map: skillId -> masteryScore (0.0-1.0)."""
    SCHEMA_VERSION = 1
    SCORE_RANGE = (0.0, 1.0)


@register(
    contract_id="mi.adaptive.recommendation",
    schema_version=1,
    semantic_version="1.0.0",
    owner="dev-5",
    compatibility="backward",
    description="Lesson recommendation from adaptive engine.",
)
class RecommendationResult:
    """Source: packages/recommendation_core (v1)."""
    SCHEMA_VERSION = 1


# ─── Analytics Contracts ──────────────────────────────────────────────────────

@register(
    contract_id="mi.analytics.event",
    schema_version=1,
    semantic_version="1.0.0",
    owner="dev-5",
    compatibility="backward",
    description="Analytics event emitted from mobile/game.",
)
class AnalyticsEvent:
    """Analytics event schema."""
    SCHEMA_VERSION = 1
    PII_FIELDS = frozenset([
        "email", "password", "pin", "accessToken", "refreshToken",
        "parentName", "parentEmail", "ipAddress",
    ])


# ─── Compatibility ────────────────────────────────────────────────────────────

COMPATIBILITY_LEVELS = {
    "patch": "PATCH — no behavior change",
    "backward": "BACKWARD — new optional fields only",
    "potentially-breaking": "POTENTIALLY-BREAKING — review required",
    "breaking": "BREAKING — migration/rollback required",
}


def check_forbidden_fields(data: dict, contract: type) -> list[str]:
    """Return list of forbidden fields found in data. Empty = clean."""
    found = []
    forbidden = getattr(contract, "FORBIDDEN_FIELDS", frozenset())
    for field in forbidden:
        if field in data:
            found.append(field)
    return found


def check_required_fields(data: dict, contract: type) -> list[str]:
    """Return list of missing required fields. Empty = valid."""
    missing = []
    required = getattr(contract, "REQUIRED_FIELDS", frozenset())
    for field in required:
        if field not in data:
            missing.append(field)
    return missing


def validate_contract_data(contract_id: str, data: dict) -> dict:
    """Validate data against a registered contract. Returns result dict."""
    if contract_id not in CONTRACT_REGISTRY:
        return {"valid": False, "error": f"Unknown contract: {contract_id}"}

    contract_def = CONTRACT_REGISTRY[contract_id]
    # Find the registered class
    for cls in [MiGameLaunchRequest, MiGameResult, MiGameSnapshot,
                LessonProgress, SyncAttemptItem, SyncProgressItem,
                LessonContent, LevelContent, SkillEvidence,
                RecommendationResult, AnalyticsEvent]:
        cid = getattr(cls, "__contract_id__", None)
        if cid == contract_id:
            break
    else:
        return {"valid": False, "error": "Contract class not found"}

    forbidden = check_forbidden_fields(data, cls)
    missing = check_required_fields(data, cls)
    valid = len(forbidden) == 0 and len(missing) == 0

    result = {
        "valid": valid,
        "contract_id": contract_id,
        "schema_version": contract_def.schema_version,
        "semantic_version": contract_def.semantic_version,
    }
    if forbidden:
        result["forbidden_fields_found"] = forbidden
    if missing:
        result["missing_required_fields"] = missing
    return result


def get_contract(contract_id: str) -> dict | None:
    """Get a contract definition by ID."""
    if contract_id in CONTRACT_REGISTRY:
        return CONTRACT_REGISTRY[contract_id].to_dict()
    return None


def list_contracts(owner: str | None = None) -> list[dict]:
    """List all registered contracts, optionally filtered by owner."""
    results = []
    for cid, cdef in sorted(CONTRACT_REGISTRY.items()):
        if owner and cdef.owner != owner:
            continue
        results.append(cdef.to_dict())
    return results
