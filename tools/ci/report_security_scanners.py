"""Summarize advisory security scanners without hiding their failures."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

ADVISORY_OUTCOMES = {"success", "failure", "skipped", "cancelled"}


def _load_json(
    path: Path, scanner: str, outcome: str
) -> tuple[dict[str, Any], list[str]]:
    errors: list[str] = []
    if not path.exists():
        if outcome == "failure":
            errors.append(
                f"{scanner} reported failure but did not produce {path.as_posix()}"
            )
        return {}, errors

    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        errors.append(f"{scanner} produced invalid JSON in {path.as_posix()}: {exc}")
        return {}, errors

    if not isinstance(data, dict):
        errors.append(f"{scanner} report must be a JSON object: {path.as_posix()}")
        return {}, errors
    return data, errors


def _pip_audit_vulnerability_count(report: dict[str, Any]) -> int:
    dependencies = report.get("dependencies", [])
    if not isinstance(dependencies, list):
        return 0

    total = 0
    for dependency in dependencies:
        if not isinstance(dependency, dict):
            continue
        vulns = dependency.get("vulns", [])
        if isinstance(vulns, list):
            total += len(vulns)
    return total


def _bandit_issue_count(report: dict[str, Any]) -> int:
    results = report.get("results", [])
    return len(results) if isinstance(results, list) else 0


def _validate_outcome(scanner: str, outcome: str) -> list[str]:
    if outcome in ADVISORY_OUTCOMES:
        return []
    return [f"{scanner} outcome {outcome!r} is not recognized"]


def _write_summary(
    summary: Path,
    *,
    pip_audit_outcome: str,
    pip_audit_count: int,
    bandit_outcome: str,
    bandit_count: int,
    errors: list[str],
) -> None:
    lines = [
        "### Security scanner outcomes",
        "",
        "| Gate | Mode | Outcome | Finding count |",
        "| --- | --- | --- | ---: |",
        "| Gitleaks secret scan | blocking | see action step | n/a |",
        (
            "| pip-audit dependency scan | advisory/report-only | "
            f"{pip_audit_outcome} | {pip_audit_count} |"
        ),
        (
            "| Bandit Python SAST scan | advisory/report-only | "
            f"{bandit_outcome} | {bandit_count} |"
        ),
        "",
        "Advisory scanner findings do not fail CI yet, but they are uploaded as JSON artifacts and listed here.",
    ]
    if errors:
        lines.extend(["", "Reporter errors:"])
        lines.extend(f"- {error}" for error in errors)
    summary.parent.mkdir(parents=True, exist_ok=True)
    with summary.open("a", encoding="utf-8") as output:
        output.write("\n".join(lines))
        output.write("\n")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pip-audit-report", required=True, type=Path)
    parser.add_argument("--bandit-report", required=True, type=Path)
    parser.add_argument("--pip-audit-outcome", required=True)
    parser.add_argument("--bandit-outcome", required=True)
    parser.add_argument("--summary", required=True, type=Path)
    args = parser.parse_args(argv)

    errors = [
        *_validate_outcome("pip-audit", args.pip_audit_outcome),
        *_validate_outcome("Bandit", args.bandit_outcome),
    ]
    pip_report, pip_errors = _load_json(
        args.pip_audit_report, "pip-audit", args.pip_audit_outcome
    )
    bandit_report, bandit_errors = _load_json(
        args.bandit_report, "Bandit", args.bandit_outcome
    )
    errors.extend(pip_errors)
    errors.extend(bandit_errors)

    pip_count = _pip_audit_vulnerability_count(pip_report)
    bandit_count = _bandit_issue_count(bandit_report)

    if args.pip_audit_outcome == "failure":
        print(
            "::warning::pip-audit is advisory/report-only and returned failure; "
            "review the uploaded JSON report."
        )
    if args.bandit_outcome == "failure":
        print(
            "::warning::Bandit is advisory/report-only and returned failure; "
            "review the uploaded JSON report."
        )

    _write_summary(
        args.summary,
        pip_audit_outcome=args.pip_audit_outcome,
        pip_audit_count=pip_count,
        bandit_outcome=args.bandit_outcome,
        bandit_count=bandit_count,
        errors=errors,
    )

    for error in errors:
        print(f"::error::{error}", file=sys.stderr)
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
