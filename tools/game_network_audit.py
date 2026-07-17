#!/usr/bin/env python3
"""Verify child-facing game code stays offline-only.

The mobile app can include networking for parent sync and backend features, but
MVP game screens must not make outbound calls, launch URLs, open web views, or
embed external endpoints. This audit scans only child-facing game source.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import asdict, dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
GAME_ROOT = ROOT / "apps" / "mobile" / "lib" / "src" / "games"


@dataclass
class Finding:
    severity: str
    category: str
    path: str
    line: int
    match: str
    note: str


@dataclass
class AuditResult:
    status: str
    scanned_files: int
    findings: list[Finding]
    summary: dict[str, int]


PROHIBITED_PATTERNS = {
    r"^\s*import\s+['\"]package:(dio|http|url_launcher|webview_flutter)/": (
        "network_import",
        "Game code must not import networking, URL launcher, or webview packages.",
    ),
    r"^\s*import\s+['\"]dart:(io|html)": (
        "network_import",
        "Game code must not import dart:io or dart:html networking surfaces.",
    ),
    r"\b(Dio|HttpClient|WebSocket|Socket|Client)\s*\(": (
        "network_api",
        "Game code must not create network clients or sockets.",
    ),
    r"\b(get|post|put|patch|delete)\s*\(\s*['\"]https?://": (
        "network_call",
        "Game code must not call external HTTP endpoints.",
    ),
    r"\b(launchUrl|canLaunchUrl|WebViewWidget|WebViewController)\b": (
        "external_link",
        "Game code must not launch links or embed web views.",
    ),
    r"https?://|www\.": (
        "external_url",
        "Game code must not contain external URLs.",
    ),
}


def iter_game_files() -> list[Path]:
    if not GAME_ROOT.exists():
        return []
    return sorted(p for p in GAME_ROOT.rglob("*.dart") if p.is_file())


def add_finding(
    findings: list[Finding],
    *,
    category: str,
    path: Path,
    line: int,
    match: str,
    note: str,
) -> None:
    findings.append(
        Finding(
            severity="fail",
            category=category,
            path=str(path.relative_to(ROOT)),
            line=line,
            match=match.strip(),
            note=note,
        )
    )


def scan_file(path: Path, findings: list[Finding]) -> None:
    text = path.read_text(encoding="utf-8", errors="replace")
    for line_no, line in enumerate(text.splitlines(), start=1):
        stripped = line.strip()
        if stripped.startswith(("//", "///")):
            continue
        for pattern, (category, note) in PROHIBITED_PATTERNS.items():
            if re.search(pattern, line, flags=re.IGNORECASE):
                add_finding(
                    findings,
                    category=category,
                    path=path,
                    line=line_no,
                    match=line,
                    note=note,
                )


def audit() -> AuditResult:
    findings: list[Finding] = []
    files = iter_game_files()
    for path in files:
        scan_file(path, findings)
    fail_count = len(findings)
    return AuditResult(
        status="fail" if fail_count else "pass",
        scanned_files=len(files),
        findings=findings,
        summary={"fail": fail_count, "warn": 0},
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true", help="Print JSON output.")
    args = parser.parse_args()

    result = audit()
    if args.json:
        print(json.dumps(asdict(result), indent=2, ensure_ascii=True))
    else:
        print(f"Status: {result.status}")
        print(f"Game files scanned: {result.scanned_files}")
        print(f"Failures: {result.summary['fail']}")
        for finding in result.findings:
            print(
                f"[FAIL] {finding.path}:{finding.line} "
                f"{finding.category} - {finding.note}"
            )
    return 0 if result.status == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
