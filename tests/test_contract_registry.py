"""Contract registry checks for the shared Phase 3 contract layer."""

from contracts.shared_contracts import (
    CONTRACT_REGISTRY,
    get_contract,
    validate_contract_data,
)


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
