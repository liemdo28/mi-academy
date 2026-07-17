import json

import pytest

from tools.content_validator import validate_content as validator


def test_validate_level_accepts_complete_bilingual_level():
    assert validator.validate_level(_level(), 1) == []


def test_validate_level_reports_missing_required_fields():
    errors = validator.validate_level({}, 2)

    assert "Level 2: Missing required field 'id'" in errors
    assert "Level 2: Missing required field 'levelNumber'" in errors
    assert "Level 2: Missing required field 'difficulty'" in errors
    assert "Level 2: Missing required field 'localizedContent'" in errors


def test_validate_level_rejects_empty_or_non_string_id():
    assert "Level 1: ID must not be empty" in validator.validate_level(
        _level(id=""),
        1,
    )
    assert "Level 1: ID must not be empty" in validator.validate_level(
        _level(id=123),
        1,
    )


def test_validate_level_rejects_non_integer_or_out_of_range_difficulty():
    assert "Level 1: difficulty must be 1-5, got hard" in validator.validate_level(
        _level(difficulty="hard"),
        1,
    )
    assert "Level 1: difficulty must be 1-5, got 6" in validator.validate_level(
        _level(difficulty=6),
        1,
    )


def test_validate_level_requires_vi_and_en_localizations():
    errors = validator.validate_level(
        _level(localizedContent={"vi": {"prompt": "Xin chao"}}),
        1,
    )

    assert "Level 1: English (en) localization missing" in errors

    errors = validator.validate_level(
        _level(localizedContent={"en": {"prompt": "Hello"}}),
        1,
    )

    assert "Level 1: Vietnamese (vi) localization required" in errors


def test_validate_level_rejects_non_map_localized_content_and_bad_hints():
    errors = validator.validate_level(_level(localizedContent=[], hints="hint"), 1)

    assert "Level 1: localizedContent must be a map" in errors
    assert "Level 1: hints must be a list" in errors


def test_validate_level_rejects_hint_without_text():
    errors = validator.validate_level(_level(hints=[{}, "bad"]), 1)

    assert "Level 1, hint 0: 'text' must not be empty" in errors
    assert "Level 1, hint 1: must be a map" in errors


def test_validate_card_pairs_accepts_exact_pairs():
    cards = [
        {"id": "a1", "pairId": "a"},
        {"id": "a2", "pairId": "a"},
        {"id": "b1", "pairId": "b"},
        {"id": "b2", "pairId": "b"},
    ]

    assert validator.validate_card_pairs(cards, 1) == []


def test_validate_card_pairs_reports_duplicate_empty_odd_and_unpaired_cards():
    cards = [
        {"id": "a1", "pairId": "a"},
        {"id": "a1", "pairId": "a"},
        {"id": "", "pairId": ""},
    ]

    errors = validator.validate_card_pairs(cards, 1)

    assert "Level 1: Duplicate card ID 'a1'" in errors
    assert "Level 1: Card has empty ID" in errors
    assert "Level 1: Card '' has empty pairId" in errors
    assert "Level 1: Total cards (3) must be even" in errors


def test_validate_word_builder_requires_letters_build_target():
    errors = validator.validate_word_builder_content(
        {
            "vi": {"targetWord": "meo", "letters": ["m", "e", "o"]},
            "en": {"targetWord": "cat", "letters": ["c", "a"]},
        },
        1,
    )

    assert "Level 1 (en): letters build 'ca', expected 'cat'" in errors


def test_validate_sound_match_requires_answer_options_audio_and_transcript():
    errors = validator.validate_sound_match_content(
        {
            "vi": {
                "correctAnswer": "a",
                "options": ["a", "a"],
                "audioKey": "",
                "audioTranscript": "",
            },
            "en": {
                "correctAnswer": "z",
                "options": ["a", "b"],
                "audioKey": "letter_z",
                "audioTranscript": "z",
            },
        },
        1,
    )

    assert "Level 1 (vi): options must be unique" in errors
    assert "Level 1 (vi): audioKey must not be empty" in errors
    assert "Level 1 (vi): audioTranscript must not be empty" in errors
    assert "Level 1 (en): correctAnswer 'z' is not in options" in errors


def test_validate_choice_options_requires_one_correct_unique_option():
    errors = validator.validate_choice_options(
        {
            "vi": {
                "prompt": "",
                "options": [
                    {"text": "4", "correct": True},
                    {"text": "4", "correct": True},
                ],
            }
        },
        1,
    )

    assert "Level 1 (vi): prompt must not be empty" in errors
    assert "Level 1 (vi): option text values must be unique" in errors
    assert "Level 1 (vi): expected exactly 1 correct option, got 2" in errors


def test_validate_robot_required_path_accepts_goal_and_collectibles():
    errors = validator.validate_robot_required_path(
        ["START", "COLLECT", "MOVE_FORWARD"],
        width=2,
        height=1,
        start={"x": 0, "y": 0, "facing": "east"},
        goal={"x": 1, "y": 0},
        obstacles=set(),
        collectibles={(0, 0)},
        level_num=1,
        locale="vi",
    )

    assert errors == []


def test_validate_robot_required_path_reports_obstacle_and_wrong_goal():
    obstacle_errors = validator.validate_robot_required_path(
        ["START", "MOVE_FORWARD"],
        width=2,
        height=1,
        start={"x": 0, "y": 0, "facing": "east"},
        goal={"x": 1, "y": 0},
        obstacles={(1, 0)},
        collectibles=set(),
        level_num=1,
        locale="vi",
    )
    wrong_goal_errors = validator.validate_robot_required_path(
        ["START", "TURN_LEFT"],
        width=2,
        height=1,
        start={"x": 0, "y": 0, "facing": "east"},
        goal={"x": 1, "y": 0},
        obstacles=set(),
        collectibles={(0, 0)},
        level_num=1,
        locale="vi",
    )

    assert (
        "Level 1 (vi): requiredCommands moves into obstacle at (1,0)"
        in obstacle_errors
    )
    assert (
        "Level 1 (vi): requiredCommands ends at (0,0), expected goal (1,0)"
        in wrong_goal_errors
    )
    assert "Level 1 (vi): requiredCommands misses collectibles [(0, 0)]" in wrong_goal_errors


def test_validate_robot_commands_level_checks_metadata_and_commands():
    errors = validator.validate_robot_commands_level(
        _robot_level(requiredCommands=["MOVE_FORWARD"], availableCommands=["JUMP"]),
        1,
    )

    assert "Level 1 (vi): unsupported command 'JUMP'" in errors
    assert "Level 1 (vi): requiredCommands must contain START plus commands" in errors


def test_validate_game_file_reports_invalid_json(tmp_path):
    path = tmp_path / "bad.json"
    path.write_text("{", encoding="utf-8")

    errors = validator.validate_game_file(path, "word_builder")

    assert errors
    assert errors[0].startswith("bad.json: Invalid JSON")


def test_validate_game_file_reports_duplicate_level_ids(tmp_path):
    path = tmp_path / "word_builder.json"
    _write_json(path, {"levels": [_level(id="same"), _level(id="same", levelNumber=2)]})

    errors = validator.validate_game_file(path, "word_builder")

    assert "Duplicate level ID: 'same'" in errors


def test_collect_audio_keys_reads_all_localizations(tmp_path):
    path = tmp_path / "sound_match.json"
    _write_json(
        path,
        {
            "levels": [
                {
                    "localizedContent": {
                        "vi": {"audioKey": "letter_a"},
                        "en": {"audioKey": "word_cat"},
                    }
                }
            ]
        },
    )

    assert validator.collect_audio_keys(path) == {"letter_a", "word_cat"}


def test_validate_audio_placeholders_accepts_manifest_and_wav_files(tmp_path, monkeypatch):
    audio_dir = tmp_path / "audio"
    audio_dir.mkdir()
    _write_json(audio_dir / "audio_manifest.json", {"assets": [{"assetKey": "letter_a"}]})
    _write_wav_header(audio_dir / "letter_a.wav")
    monkeypatch.setattr(validator, "MOBILE_ASSETS", tmp_path)

    assert validator.validate_audio_placeholders({"letter_a"}) == []


def test_validate_audio_placeholders_reports_manifest_file_and_header_errors(
    tmp_path,
    monkeypatch,
):
    audio_dir = tmp_path / "audio"
    audio_dir.mkdir()
    _write_json(audio_dir / "audio_manifest.json", {"assets": [{"assetKey": "letter_a"}]})
    (audio_dir / "letter_a.wav").write_bytes(b"not-a-wave")
    monkeypatch.setattr(validator, "MOBILE_ASSETS", tmp_path)

    errors = validator.validate_audio_placeholders({"letter_a", "missing"})

    assert "Audio file letter_a.wav is not a valid WAV placeholder" in errors
    assert "Audio key 'missing' missing from audio_manifest.json" in errors
    assert "Audio key 'missing' missing file missing.wav" in errors


def _level(**overrides):
    data = {
        "id": "level-1",
        "levelNumber": 1,
        "difficulty": 1,
        "localizedContent": {
            "vi": {"prompt": "Xin chao"},
            "en": {"prompt": "Hello"},
        },
        "hints": [{"text": "Thu tiep nhe"}],
    }
    data.update(overrides)
    return data


def _robot_level(**vi_overrides):
    vi = {
        "availableCommands": ["MOVE_FORWARD"],
        "requiredCommands": ["START", "MOVE_FORWARD"],
    }
    vi.update(vi_overrides)
    return {
        "metadata": {
            "grid": {"width": 2, "height": 1},
            "start": {"x": 0, "y": 0, "facing": "east"},
            "goal": {"x": 1, "y": 0},
            "obstacles": [],
            "collectibles": [],
        },
        "localizedContent": {"vi": vi},
    }


def _write_json(path, data):
    path.write_text(json.dumps(data), encoding="utf-8")


def _write_wav_header(path):
    path.write_bytes(b"RIFF\x24\x00\x00\x00WAVEfmt ")
