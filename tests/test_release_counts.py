from tools.release_counts import compute_release_counts


def test_release_counts_track_games_1_through_30_scope():
    counts = compute_release_counts()

    assert counts.games == 30
    assert counts.production_levels == 1655
    assert len({summary.game_id for summary in counts.level_files}) == 30
