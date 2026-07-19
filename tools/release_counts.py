"""Compute release-scope game and level counts from production assets."""

from __future__ import annotations

import argparse
import json
from dataclasses import asdict, dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LEVELS_DIR = ROOT / "apps" / "mobile" / "assets" / "levels"


@dataclass(frozen=True)
class GameLevelSummary:
    game_id: str
    level_count: int


@dataclass(frozen=True)
class ReleaseCounts:
    games: int
    production_levels: int
    level_files: list[GameLevelSummary]


def compute_release_counts(levels_dir: Path = LEVELS_DIR) -> ReleaseCounts:
    summaries: list[GameLevelSummary] = []
    for level_file in sorted(levels_dir.glob("*.json")):
        data = json.loads(level_file.read_text(encoding="utf-8"))
        game_id = str(data["gameId"])
        levels = data["levels"]
        if not isinstance(levels, list):
            raise TypeError(f"{level_file}: levels must be a list")
        summaries.append(GameLevelSummary(game_id=game_id, level_count=len(levels)))

    return ReleaseCounts(
        games=len(summaries),
        production_levels=sum(summary.level_count for summary in summaries),
        level_files=summaries,
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--json", action="store_true", help="emit machine-readable JSON"
    )
    args = parser.parse_args()

    counts = compute_release_counts()
    payload = {
        "games": counts.games,
        "production_levels": counts.production_levels,
        "level_files": [asdict(summary) for summary in counts.level_files],
    }
    if args.json:
        print(json.dumps(payload, indent=2, sort_keys=True))
    else:
        print(f"games: {counts.games}")
        print(f"production_levels: {counts.production_levels}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
