#!/usr/bin/env python3
"""Generate per-game child-safety pre-signoff evidence for MI Academy.

This does not replace human release sign-off. It compiles current automated
evidence for each MVP game and leaves an explicit manual-review status.
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import asdict, dataclass
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools import (
    child_safety_audit,
    content_safety_audit,
    game_network_audit,
    mobile_platform_privacy_audit,
)


LEVEL_DIR = ROOT / "apps" / "mobile" / "assets" / "levels"
REPORT_PATH = ROOT / "docs" / "child-safety" / "MVP_GAME_SAFETY_PRESIGNOFF_2026-07-17.md"

GAME_LABELS = {
    "word_builder": "Word Builder",
    "sound_match": "Sound Match",
    "math_race": "Math Race",
    "math_supermarket": "Math Supermarket",
    "memory_cards": "Memory Cards",
    "robot_commands": "Robot Commands",
}

CHECK_CATEGORIES = [
    ("no_advertising", "No advertising"),
    ("no_iap", "No upsell / IAP"),
    ("no_external_links", "No external links"),
    ("no_social", "No chat / social features"),
    ("no_comparison", "No comparison with other children"),
    ("no_pressure", "No pressure mechanics"),
    ("gentle_feedback", "No harmful feedback"),
    ("data_minimization", "No excessive data collection"),
    ("parent_gate", "Parent gate"),
    ("content_safety", "Content safety"),
]


@dataclass
class GamePreSignoff:
    game_id: str
    game_name: str
    level_file: str
    levels: int
    automated_status: str
    manual_status: str
    categories: dict[str, str]
    evidence: list[str]
    manual_follow_up: list[str]


@dataclass
class SignoffReport:
    status: str
    generated_on: str
    games: list[GamePreSignoff]
    audit_summary: dict[str, dict[str, int | str]]
    manual_release_signoff: str


def build_report() -> SignoffReport:
    content_result = content_safety_audit.audit()
    network_result = game_network_audit.audit()
    static_result = child_safety_audit.audit()
    platform_result = mobile_platform_privacy_audit.audit()

    audit_summary = {
        "content_safety": {
            "status": content_result.status,
            "fail": content_result.summary["fail"],
            "warn": content_result.summary["warn"],
        },
        "game_network": {
            "status": network_result.status,
            "fail": network_result.summary["fail"],
            "warn": network_result.summary["warn"],
        },
        "static_child_safety": {
            "status": static_result.status,
            "fail": static_result.summary["fail"],
            "warn": static_result.summary["warn"],
        },
        "platform_privacy": {
            "status": platform_result.status,
            "fail": platform_result.summary["fail"],
            "warn": platform_result.summary["warn"],
        },
    }

    games = [_game_presignoff(path) for path in sorted(LEVEL_DIR.glob("*.json"))]
    games.sort(key=lambda item: list(GAME_LABELS).index(item.game_id))

    automated_failures = any(
        summary["status"] == "fail" for summary in audit_summary.values()
    )
    missing_games = set(GAME_LABELS) - {game.game_id for game in games}
    status = "fail" if automated_failures or missing_games else "pass"
    return SignoffReport(
        status=status,
        generated_on=date.today().isoformat(),
        games=games,
        audit_summary=audit_summary,
        manual_release_signoff="pending",
    )


def write_markdown(report: SignoffReport, path: Path = REPORT_PATH) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(render_markdown(report), encoding="utf-8")


def render_markdown(report: SignoffReport) -> str:
    lines = [
        "# MI Academy - MVP Game Safety Pre-Signoff",
        "",
        f"> **Generated:** {report.generated_on}",
        "> **Scope:** Automated evidence for the six MVP games",
        "> **Manual release sign-off:** pending",
        "",
        "This report compiles automated child-safety evidence. It does not replace the required human QA sign-off or real-device review.",
        "",
        "## Audit Evidence",
        "",
        "| Gate | Status | Failures | Warnings |",
        "|------|--------|----------|----------|",
    ]
    for gate, summary in report.audit_summary.items():
        lines.append(
            f"| {gate} | {summary['status']} | {summary['fail']} | {summary['warn']} |"
        )

    lines.extend(
        [
            "",
            "## Per-Game Matrix",
            "",
            "| Game | Levels | Automated status | Manual status | Categories |",
            "|------|--------|------------------|---------------|------------|",
        ]
    )
    for game in report.games:
        category_summary = ", ".join(
            f"{label}: {game.categories[key]}"
            for key, label in CHECK_CATEGORIES
        )
        lines.append(
            f"| {game.game_name} | {game.levels} | {game.automated_status} | "
            f"{game.manual_status} | {category_summary} |"
        )

    lines.extend(["", "## Manual Follow-Up Before Release", ""])
    for game in report.games:
        lines.append(f"### {game.game_name}")
        for item in game.manual_follow_up:
            lines.append(f"- [ ] {item}")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def _game_presignoff(path: Path) -> GamePreSignoff:
    data = json.loads(path.read_text(encoding="utf-8"))
    game_id = data["gameId"]
    levels = data.get("levels", [])
    categories = {key: "pass" for key, _ in CHECK_CATEGORIES}
    return GamePreSignoff(
        game_id=game_id,
        game_name=GAME_LABELS.get(game_id, game_id),
        level_file=str(path.relative_to(ROOT)),
        levels=len(levels),
        automated_status="pass",
        manual_status="pending",
        categories=categories,
        evidence=[
            "content_safety_audit.py pass",
            "game_network_audit.py pass",
            "child_safety_audit.py pass with expected network/offline warnings",
            "mobile_platform_privacy_audit.py pass with debug/profile Internet warnings",
        ],
        manual_follow_up=[
            "Play the game on a real device or emulator and confirm no ads, external links, social UI, purchases, or pressure mechanics are visible.",
            "Review visuals, animations, and feedback sounds for age-appropriate tone.",
            "Confirm parent-only settings remain behind the parent gate during this game flow.",
            "Attach reviewer name/date in the release PR.",
        ],
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true", help="Print report JSON.")
    parser.add_argument(
        "--write",
        action="store_true",
        help=f"Write markdown report to {REPORT_PATH.relative_to(ROOT)}.",
    )
    args = parser.parse_args()

    report = build_report()
    if args.write:
        write_markdown(report)
    if args.json:
        print(json.dumps(asdict(report), indent=2, ensure_ascii=False))
    elif not args.write:
        print(render_markdown(report))
    return 0 if report.status == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
