"""MI Academy shared contracts — single source of truth for all contracts."""

from __future__ import annotations

from typing import Callable, TypeVar

# ─── Contract Registry ───────────────────────────────────────────────────────
# All contracts must be registered here with their current version.

CONTRACT_REGISTRY: dict[str, ContractDef] = {}

_T = TypeVar("_T", bound=type)


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
) -> Callable[[_T], _T]:
    """Decorator to register a contract definition."""

    def decorator(cls: _T) -> _T:
        # Dynamic attribute injection -- every contract class gets a
        # `__contract_id__` marker this way rather than each declaring it
        # manually, so it isn't part of any class's static type.
        cls.__contract_id__ = contract_id  # type: ignore[attr-defined]
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
        "contract_id",
        "schema_version",
        "semantic_version",
        "owner",
        "compatibility",
        "description",
        "deprecated_fields",
        "migration_path",
        "deprecation_date",
        "minimum_app_version",
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
    """Source: packages/mi_game_core/lib/src/contracts/mi_game_launch_request.dart MiGameLaunchRequest (v1)."""

    SCHEMA_VERSION = 1
    REQUIRED_FIELDS = frozenset(
        [
            "schemaVersion",
            "childProfileId",
            "gameId",
            "levelId",
            "language",
            "ageGroup",
            "accessibility",
            "audioPreferences",
            "levelContent",
        ]
    )
    FORBIDDEN_FIELDS = frozenset(
        [
            "accessToken",
            "refreshToken",
            "password",
            "parentEmail",
            "parentId",
            "pin",
            "authToken",
        ]
    )


@register(
    contract_id="mi.game.result",
    schema_version=1,
    semantic_version="1.0.0",
    owner="dev-2",
    compatibility="backward",
    description="Game-to-platform result with mastery and skill evidence.",
)
class MiGameResult:
    """Source: packages/mi_game_core/lib/src/contracts/mi_game_result.dart MiGameResult (v1)."""

    SCHEMA_VERSION = 1
    REQUIRED_FIELDS = frozenset(
        [
            "schemaVersion",
            "attemptId",
            "childProfileId",
            "gameId",
            "levelId",
            "startedAt",
            "completedAt",
            "attemptCount",
            "correctCount",
            "incorrectCount",
            "hintCount",
            "durationSeconds",
            "completed",
            "masteryEvidence",
            "skillEvidence",
        ]
    )
    FORBIDDEN_FIELDS = frozenset(
        [
            "accessToken",
            "refreshToken",
            "password",
            "parentEmail",
            "parentId",
            "pin",
        ]
    )
    MASTERY_EVIDENCE_RANGE = (0.0, 1.0)


@register(
    contract_id="mi.game.snapshot",
    schema_version=2,
    semantic_version="2.0.0",
    owner="dev-2",
    compatibility="backward",
    description="In-progress game state for save/resume across sessions.",
    migration_path="SnapshotMigrator.migrate",
)
class MiGameSnapshot:
    """Source: packages/mi_game_core/lib/src/models/mi_game_snapshot.dart MiGameSnapshot (v2).
    Note: `savedAt` here is the contract-facing name; the Dart class's own
    field is `createdAt` with `savedAt` as a getter alias (see that file),
    and the wire JSON key is `saved_at`. Intentional, not drift."""

    SCHEMA_VERSION = 2
    REQUIRED_FIELDS = frozenset(
        [
            "schemaVersion",
            "gameVersion",
            "gameId",
            "levelId",
            "childProfileId",
            "savedAt",
            "state",
        ]
    )
    FORBIDDEN_FIELDS = frozenset(
        [
            "accessToken",
            "refreshToken",
            "password",
            "parentEmail",
        ]
    )


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
    """No current Dart-side model backs this contract -- the class this
    docstring used to cite (shared_models.dart) was deleted as dead code
    in a prior cleanup pass. STATUS_PYTHON_MAP is not read by any route
    (apps/api/schemas' ProgressResponse.status returns the Python
    snake_case value as-is, e.g. "needs_practice", not "needsPractice"),
    and no mobile code branches on a camelCase status string either --
    this mapping is aspirational/unused on both sides today, not an
    active contract violation."""

    SCHEMA_VERSION = 1
    STATUS_VALUES = frozenset(
        ["notStarted", "learning", "completed", "needsPractice", "mastered"]
    )
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
    REQUIRED_FIELDS = frozenset(
        [
            "id",
            "childId",
            "lessonId",
            "gameId",
            "questionId",
            "answerJson",
            "isCorrect",
            "responseTimeMs",
            "hintCount",
            "createdAt",
        ]
    )


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
    contract_id="mi.parent.profile",
    schema_version=1,
    semantic_version="1.0.0",
    owner="dev-1",
    compatibility="backward",
    description="Parent profile returned by parent/profile APIs.",
)
class ParentProfileContract:
    SCHEMA_VERSION = 1
    FORBIDDEN_FIELDS = frozenset(["password", "pin", "accessToken", "refreshToken"])


@register(
    contract_id="mi.child.profile",
    schema_version=1,
    semantic_version="1.0.0",
    owner="dev-1",
    compatibility="backward",
    description="Child profile owned by a parent account.",
)
class ChildProfileContract:
    SCHEMA_VERSION = 1
    FORBIDDEN_FIELDS = frozenset(
        ["parentEmail", "password", "pin", "accessToken", "refreshToken"]
    )


@register(
    contract_id="mi.auth.session",
    schema_version=1,
    semantic_version="1.0.0",
    owner="dev-1",
    compatibility="backward",
    description="Authenticated session token response.",
)
class AuthSessionContract:
    SCHEMA_VERSION = 1
    REQUIRED_FIELDS = frozenset(["accessToken", "refreshToken", "tokenType"])


@register(
    contract_id="mi.lesson",
    schema_version=1,
    semantic_version="1.0.0",
    owner="dev-3",
    compatibility="backward",
    description="Lesson catalog and detail payload.",
)
class LessonContract:
    SCHEMA_VERSION = 1


@register(
    contract_id="mi.skill",
    schema_version=1,
    semantic_version="1.0.0",
    owner="dev-3",
    compatibility="backward",
    description="Skill taxonomy entry.",
)
class SkillContract:
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


@register(
    contract_id="mi.reward",
    schema_version=1,
    semantic_version="1.0.0",
    owner="dev-1",
    compatibility="backward",
    description="Reward catalog and child unlock state.",
)
class RewardContract:
    SCHEMA_VERSION = 1


@register(
    contract_id="mi.sync.event",
    schema_version=1,
    semantic_version="1.0.0",
    owner="dev-1",
    compatibility="backward",
    description="Offline sync queue event envelope.",
)
class SyncEventContract:
    SCHEMA_VERSION = 1
    REQUIRED_FIELDS = frozenset(
        ["id", "childProfileId", "type", "payload", "createdAt"]
    )


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


@register(
    contract_id="mi.mastery.evidence",
    schema_version=1,
    semantic_version="1.0.0",
    owner="dev-5",
    compatibility="backward",
    description="Mastery evidence derived from game result skill signals.",
)
class MasteryEvidenceContract:
    SCHEMA_VERSION = 1


@register(
    contract_id="mi.recommendation",
    schema_version=1,
    semantic_version="1.0.0",
    owner="dev-5",
    compatibility="backward",
    description="Daily plan recommendation payload.",
)
class RecommendationContract:
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
    PII_FIELDS = frozenset(
        [
            "email",
            "password",
            "pin",
            "accessToken",
            "refreshToken",
            "parentName",
            "parentEmail",
            "ipAddress",
        ]
    )


@register(
    contract_id="mi.content.manifest",
    schema_version=1,
    semantic_version="1.0.0",
    owner="dev-3",
    compatibility="backward",
    description="Content manifest for language and curriculum bundles.",
)
class ContentManifestContract:
    SCHEMA_VERSION = 1


@register(
    contract_id="mi.asset.manifest",
    schema_version=1,
    semantic_version="1.0.0",
    owner="dev-4",
    compatibility="backward",
    description="Asset manifest and resolver payload.",
)
class AssetManifestContract:
    SCHEMA_VERSION = 1


@register(
    contract_id="mi.api.error",
    schema_version=1,
    semantic_version="1.0.0",
    owner="dev-7",
    compatibility="backward",
    description="Structured API error response.",
)
class ApiErrorContract:
    SCHEMA_VERSION = 1
    REQUIRED_FIELDS = frozenset(["error"])


# ─── Compatibility ────────────────────────────────────────────────────────────

COMPATIBILITY_LEVELS = {
    "patch": "PATCH — no behavior change",
    "backward": "BACKWARD — new optional fields only",
    "potentially-breaking": "POTENTIALLY-BREAKING — review required",
    "breaking": "BREAKING — migration/rollback required",
}


def check_forbidden_fields(data: dict, contract: type) -> list[str]:
    """Return list of forbidden fields found in data. Empty = clean."""
    found: list[str] = []
    forbidden: frozenset[str] = getattr(contract, "FORBIDDEN_FIELDS", frozenset())
    for field in forbidden:
        if field in data:
            found.append(field)
    return found


def check_required_fields(data: dict, contract: type) -> list[str]:
    """Return list of missing required fields. Empty = valid."""
    missing: list[str] = []
    required: frozenset[str] = getattr(contract, "REQUIRED_FIELDS", frozenset())
    for field in required:
        if field not in data:
            missing.append(field)
    return missing


def validate_contract_data(contract_id: str, data: dict) -> dict:
    """Validate data against a registered contract. Returns result dict."""
    if contract_id not in CONTRACT_REGISTRY:
        return {"valid": False, "error": f"Unknown contract: {contract_id}"}

    contract_def = CONTRACT_REGISTRY[contract_id]
    contract_classes = {
        getattr(value, "__contract_id__", None): value
        for value in globals().values()
        if isinstance(value, type) and getattr(value, "__contract_id__", None)
    }
    cls = contract_classes.get(contract_id)
    if cls is None:
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
