"""Contract registry checks for the shared Phase 3 contract layer."""

import json
from pathlib import Path

from contracts.shared_contracts import (
    CONTRACT_REGISTRY,
    get_contract,
    validate_contract_data,
)


PROJECT_ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = PROJECT_ROOT / "contracts" / "contract_manifest.json"
REQUIRED_PHASE_3_CONTRACTS = {
    "mi.parent.profile",
    "mi.child.profile",
    "mi.auth.session",
    "mi.lesson",
    "mi.skill",
    "mi.game.launch",
    "mi.game.result",
    "mi.game.snapshot",
    "mi.progress",
    "mi.reward",
    "mi.sync.event",
    "mi.analytics.event",
    "mi.mastery.evidence",
    "mi.recommendation",
    "mi.content.manifest",
    "mi.asset.manifest",
    "mi.api.error",
}


def _valid_game_result(**overrides):
    data = {
        "schemaVersion": 1,
        "attemptId": "attempt-1",
        "childProfileId": "child-1",
        "gameId": "memory_cards",
        "levelId": "level-1",
        "startedAt": "2026-07-17T08:00:00Z",
        "completedAt": "2026-07-17T08:01:00Z",
        "attemptCount": 5,
        "correctCount": 4,
        "incorrectCount": 1,
        "hintCount": 0,
        "durationSeconds": 60,
        "completed": True,
        "masteryEvidence": 0.8,
        "skillEvidence": {"memory.visual": 0.8},
        "metadata": {"fixture": "phase-3"},
    }
    data.update(overrides)
    return data


def test_all_contracts_have_attached_contract_ids():
    assert CONTRACT_REGISTRY
    assert get_contract("mi.game.result")["schema_version"] == 1

    result = validate_contract_data("mi.game.result", _valid_game_result())

    assert result["valid"] is True
    assert result["contract_id"] == "mi.game.result"
    assert result["schema_version"] == 1


def test_contract_manifest_covers_every_phase_3_contract_family():
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    contract_ids = {contract["id"] for contract in manifest["contracts"]}

    assert REQUIRED_PHASE_3_CONTRACTS.issubset(contract_ids)
    assert REQUIRED_PHASE_3_CONTRACTS.issubset(CONTRACT_REGISTRY.keys())
    assert manifest["policy"]["wireCasing"] == "snake_case"
    assert manifest["policy"]["dartCasing"] == "camelCase"
    assert "DTO toJson/fromJson only" in manifest["policy"]["conversionLayer"]


def test_contract_manifest_fixtures_exist_when_declared():
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))

    for contract in manifest["contracts"]:
        fixture = contract.get("fixture")
        if fixture:
            assert (PROJECT_ROOT / fixture).exists(), fixture
        assert contract["schemaVersion"] >= 1
        assert contract["compatibility"] in {
            "patch",
            "backward",
            "potentially-breaking",
            "breaking",
        }


def test_openapi_snapshot_schema_matches_v2_contract_manifest():
    openapi = (PROJECT_ROOT / "contracts" / "openapi.yaml").read_text(encoding="utf-8")

    assert "MiGameSnapshot:" in openapi
    assert "required: [schema_version, game_version, game_id, level_id, child_profile_id, saved_at, state]" in openapi
    assert "default: 2" in openapi
    assert "game_version:" in openapi
    assert "checksum:" in openapi


def test_contract_validation_rejects_missing_required_fields():
    data = _valid_game_result()
    del data["attemptId"]

    result = validate_contract_data("mi.game.result", data)

    assert result["valid"] is False
    assert result["missing_required_fields"] == ["attemptId"]


def test_contract_validation_rejects_forbidden_parent_or_secret_fields():
    result = validate_contract_data(
        "mi.game.result",
        _valid_game_result(accessToken="secret-token", parentEmail="parent@example.test"),
    )

    assert result["valid"] is False
    assert set(result["forbidden_fields_found"]) == {"accessToken", "parentEmail"}


def test_contract_validation_allows_unknown_additive_fields_for_backward_compatibility():
    result = validate_contract_data(
        "mi.game.result",
        _valid_game_result(optionalNewField={"ignoredByV1": True}),
    )

    assert result["valid"] is True
