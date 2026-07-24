from pathlib import Path

from tools import child_safety_signoff


def test_signoff_report_covers_all_bundled_games():
    report = child_safety_signoff.build_report()

    assert report.status == "pass"
    assert {game.game_id for game in report.games} == set(
        child_safety_signoff.GAME_LABELS
    )
    assert all(game.levels >= 10 for game in report.games)


def test_every_game_has_ten_automated_categories_and_manual_pending():
    report = child_safety_signoff.build_report()
    expected_categories = {key for key, _ in child_safety_signoff.CHECK_CATEGORIES}

    for game in report.games:
        assert game.automated_status == "pass"
        assert game.manual_status == "pending"
        assert set(game.categories) == expected_categories
        assert all(status == "pass" for status in game.categories.values())
        assert game.manual_follow_up


def test_markdown_report_states_manual_boundary():
    report = child_safety_signoff.build_report()
    markdown = child_safety_signoff.render_markdown(report)

    assert "Manual release sign-off:** pending" in markdown
    assert "does not replace the required human QA sign-off" in markdown
    assert "Word Builder" in markdown
    assert "Robot Commands" in markdown


def test_write_markdown_report(tmp_path):
    report = child_safety_signoff.build_report()
    output = tmp_path / "presignoff.md"

    child_safety_signoff.write_markdown(report, output)

    assert output.exists()
    assert output.read_text(encoding="utf-8").startswith(
        "# MI Academy - Game Safety Pre-Signoff"
    )


def test_report_paths_are_repo_relative():
    report = child_safety_signoff.build_report()

    for game in report.games:
        assert not Path(game.level_file).is_absolute()
