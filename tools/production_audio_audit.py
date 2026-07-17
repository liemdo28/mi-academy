#!/usr/bin/env python3
"""Production audio readiness audit for MI Academy.

This is intentionally stricter than the content validator. The content
validator allows silent placeholder WAVs so developers can run the MVP locally.
This audit is for release readiness and fails until every audio asset is a
reviewed, non-placeholder production recording.
"""

from __future__ import annotations

import argparse
import json
import wave
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent.parent
MOBILE = ROOT / "apps" / "mobile"
AUDIO_DIR = ROOT / "apps" / "mobile" / "assets" / "audio"
MANIFEST = AUDIO_DIR / "audio_manifest.json"


@dataclass
class Finding:
    severity: str
    asset_key: str
    path: str
    note: str


@dataclass
class AuditResult:
    status: str
    assets_scanned: int
    approved_assets: int
    placeholder_assets: int
    findings: list[Finding]
    summary: dict[str, int]


def load_manifest(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def audio_duration_seconds(path: Path) -> float:
    with wave.open(str(path), "rb") as audio:
        frames = audio.getnframes()
        rate = audio.getframerate()
        if rate <= 0:
            return 0.0
        return frames / float(rate)


def resolve_asset_path(file_value: str, asset_key: str) -> Path:
    if not file_value:
        return AUDIO_DIR / f"{asset_key}.wav"
    path = Path(file_value)
    if path.is_absolute():
        return path
    if path.parts[:2] == ("assets", "audio"):
        return MOBILE / path
    return ROOT / path


def add(
    findings: list[Finding],
    *,
    severity: str,
    asset_key: str,
    path: Path,
    note: str,
) -> None:
    findings.append(
        Finding(
            severity=severity,
            asset_key=asset_key,
            path=str(path.relative_to(ROOT)) if path.is_absolute() else str(path),
            note=note,
        )
    )


def audit() -> AuditResult:
    findings: list[Finding] = []
    if not MANIFEST.exists():
        add(
            findings,
            severity="fail",
            asset_key="manifest",
            path=MANIFEST,
            note="audio_manifest.json is missing.",
        )
        return AuditResult(
            status="fail",
            assets_scanned=0,
            approved_assets=0,
            placeholder_assets=0,
            findings=findings,
            summary={"fail": 1, "warn": 0},
        )

    manifest = load_manifest(MANIFEST)
    assets = manifest.get("assets", [])
    if not isinstance(assets, list):
        add(
            findings,
            severity="fail",
            asset_key="manifest",
            path=MANIFEST,
            note="Manifest field 'assets' must be a list.",
        )
        assets = []

    seen_keys: set[str] = set()
    approved_assets = 0
    placeholder_assets = 0

    for index, item in enumerate(assets):
        if not isinstance(item, dict):
            add(
                findings,
                severity="fail",
                asset_key=f"asset[{index}]",
                path=MANIFEST,
                note="Manifest asset entry must be an object.",
            )
            continue

        asset_key = str(item.get("assetKey", "")).strip()
        file_value = str(item.get("file", "")).strip()
        if not asset_key:
            asset_key = f"asset[{index}]"
            add(
                findings,
                severity="fail",
                asset_key=asset_key,
                path=MANIFEST,
                note="Asset is missing assetKey.",
            )
        elif asset_key in seen_keys:
            add(
                findings,
                severity="fail",
                asset_key=asset_key,
                path=MANIFEST,
                note="Duplicate assetKey in audio manifest.",
            )
        seen_keys.add(asset_key)

        audio_path = resolve_asset_path(file_value, asset_key)
        if not file_value:
            add(
                findings,
                severity="fail",
                asset_key=asset_key,
                path=MANIFEST,
                note="Asset is missing file path.",
            )
        if not audio_path.exists():
            add(
                findings,
                severity="fail",
                asset_key=asset_key,
                path=audio_path,
                note="Audio file is missing.",
            )
            continue

        try:
            duration = audio_duration_seconds(audio_path)
        except wave.Error as exc:
            add(
                findings,
                severity="fail",
                asset_key=asset_key,
                path=audio_path,
                note=f"Audio file is not a valid WAV file: {exc}.",
            )
            continue

        if duration <= 0:
            add(
                findings,
                severity="fail",
                asset_key=asset_key,
                path=audio_path,
                note="Production audio must have non-zero duration.",
            )

        if item.get("placeholder") is True:
            placeholder_assets += 1
            add(
                findings,
                severity="fail",
                asset_key=asset_key,
                path=audio_path,
                note="Placeholder audio is not allowed for production release.",
            )

        if item.get("reviewStatus") != "approved":
            add(
                findings,
                severity="fail",
                asset_key=asset_key,
                path=MANIFEST,
                note="Audio asset must have reviewStatus='approved'.",
            )
        else:
            approved_assets += 1

        speaker = str(item.get("speaker", "")).strip().lower()
        if not speaker or speaker == "placeholder":
            add(
                findings,
                severity="fail",
                asset_key=asset_key,
                path=MANIFEST,
                note="Audio asset must identify a non-placeholder speaker/source.",
            )

        transcript = str(item.get("transcript", ""))
        language = str(item.get("language", ""))
        if language not in {"none", "sfx"} and not transcript.strip():
            add(
                findings,
                severity="fail",
                asset_key=asset_key,
                path=MANIFEST,
                note="Localized voice audio must include a transcript.",
            )

    fail_count = sum(1 for finding in findings if finding.severity == "fail")
    warn_count = sum(1 for finding in findings if finding.severity == "warn")
    return AuditResult(
        status="fail" if fail_count else "pass",
        assets_scanned=len(assets),
        approved_assets=approved_assets,
        placeholder_assets=placeholder_assets,
        findings=findings,
        summary={"fail": fail_count, "warn": warn_count},
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true", help="Print JSON output.")
    args = parser.parse_args()

    result = audit()
    if args.json:
        print(json.dumps(asdict(result), indent=2, ensure_ascii=False))
    else:
        print(f"Status: {result.status}")
        print(f"Assets scanned: {result.assets_scanned}")
        print(f"Approved assets: {result.approved_assets}")
        print(f"Placeholder assets: {result.placeholder_assets}")
        print(f"Failures: {result.summary['fail']}")
        for finding in result.findings:
            print(
                f"[{finding.severity.upper()}] {finding.asset_key} "
                f"{finding.path} - {finding.note}"
            )
    return 0 if result.status == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
