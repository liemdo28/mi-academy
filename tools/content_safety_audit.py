#!/usr/bin/env python3
"""Audit child-facing level content for MI Academy safety rules.

The static child-safety audit scans source code and manifests. This tool scans
authored level JSON so prompts, hints, options, transcripts, and metadata cannot
silently introduce pressure mechanics, harsh wording, external links, social
features, or purchase/advertising language.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent.parent
LEVEL_DIR = ROOT / "apps" / "mobile" / "assets" / "levels"


@dataclass
class Finding:
    severity: str
    category: str
    path: str
    location: str
    match: str
    note: str


@dataclass
class AuditResult:
    status: str
    files_scanned: int
    strings_scanned: int
    findings: list[Finding]
    summary: dict[str, int]


PROHIBITED_TEXT_PATTERNS = {
    r"https?://|www\.": (
        "external_links",
        "Child-facing content must not include external links.",
    ),
    r"\b(leaderboard|friend request|social feed|facebook|instagram|tiktok)\b": (
        "social",
        "Social or leaderboard language is not allowed.",
    ),
    r"\b(premium|subscribe|subscription|in-app purchase|buy coins|unlock more)\b": (
        "purchase",
        "Purchase, subscription, or upsell language is not allowed.",
    ),
    r"\b(wrong!|you lost|failed|fail|lost your streak|lose progress)\b": (
        "harsh_feedback",
        "Harsh, loss, or punitive feedback is not allowed.",
    ),
    r"\b(countdown pressure|come back tomorrow|don't stop|do not stop)\b": (
        "pressure",
        "Pressure or habit-punishment language is not allowed.",
    ),
    r"\b(email address|phone number|location|gps|camera|contacts)\b": (
        "privacy",
        "Child-facing content must not request personal or sensitive data.",
    ),
}

PROHIBITED_VI_TEXT_PATTERNS = {
    r"\b(sai rồi|con thua|quá chậm|mất chuỗi|đừng nghỉ|mất sao)\b": (
        "harsh_feedback",
        "Vietnamese harsh, loss, or pressure wording is not allowed.",
    ),
    r"\b(mua vật phẩm|mở khóa thêm|gói cao cấp|đăng ký gói)\b": (
        "purchase",
        "Vietnamese purchase or upsell language is not allowed.",
    ),
    r"\b(số điện thoại|địa chỉ email|vị trí gps|định vị|địa chỉ nhà|liên hệ|máy ảnh)\b": (
        "privacy",
        "Vietnamese child-facing content must not request sensitive data.",
    ),
}


def add(
    findings: list[Finding],
    *,
    severity: str,
    category: str,
    path: Path,
    location: str,
    match: str,
    note: str,
) -> None:
    findings.append(
        Finding(
            severity=severity,
            category=category,
            path=str(path.relative_to(ROOT)),
            location=location,
            match=match,
            note=note,
        )
    )


def walk_strings(value: Any, location: str = "$") -> list[tuple[str, str]]:
    if isinstance(value, str):
        return [(location, value)]
    if isinstance(value, dict):
        result: list[tuple[str, str]] = []
        for key, nested in value.items():
            result.extend(walk_strings(nested, f"{location}.{key}"))
        return result
    if isinstance(value, list):
        result = []
        for index, nested in enumerate(value):
            result.extend(walk_strings(nested, f"{location}[{index}]"))
        return result
    return []


def scan_text(path: Path, location: str, text: str, findings: list[Finding]) -> None:
    patterns = dict(PROHIBITED_TEXT_PATTERNS)
    patterns.update(PROHIBITED_VI_TEXT_PATTERNS)
    for pattern, (category, note) in patterns.items():
        match = re.search(pattern, text, flags=re.IGNORECASE)
        if match:
            add(
                findings,
                severity="fail",
                category=category,
                path=path,
                location=location,
                match=match.group(0),
                note=note,
            )


def scan_metadata(path: Path, data: Any, findings: list[Finding]) -> None:
    if not isinstance(data, dict):
        return
    for level_index, level in enumerate(data.get("levels", [])):
        if not isinstance(level, dict):
            continue
        metadata = level.get("metadata", {})
        if not isinstance(metadata, dict):
            continue
        time_limit = metadata.get("timeLimitSec")
        if isinstance(time_limit, (int, float)) and time_limit > 0:
            add(
                findings,
                severity="fail",
                category="pressure",
                path=path,
                location=f"$.levels[{level_index}].metadata.timeLimitSec",
                match=str(time_limit),
                note="Positive time limits can create countdown pressure and are not allowed for MVP child-facing levels.",
            )


def audit() -> AuditResult:
    findings: list[Finding] = []
    files = sorted(LEVEL_DIR.glob("*.json"))
    strings_scanned = 0
    for path in files:
        with path.open("r", encoding="utf-8") as handle:
            data = json.load(handle)
        strings = walk_strings(data)
        strings_scanned += len(strings)
        for location, text in strings:
            scan_text(path, location, text, findings)
        scan_metadata(path, data, findings)

    fail_count = sum(1 for finding in findings if finding.severity == "fail")
    warn_count = sum(1 for finding in findings if finding.severity == "warn")
    return AuditResult(
        status="fail" if fail_count else "pass",
        files_scanned=len(files),
        strings_scanned=strings_scanned,
        findings=findings,
        summary={"fail": fail_count, "warn": warn_count},
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
        print(f"Files scanned: {result.files_scanned}")
        print(f"Strings scanned: {result.strings_scanned}")
        print(f"Failures: {result.summary['fail']}")
        for finding in result.findings:
            print(
                f"[{finding.severity.upper()}] {finding.path} "
                f"{finding.location} {finding.category} - {finding.note}"
            )
    return 0 if result.status == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
