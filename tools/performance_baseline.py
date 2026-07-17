#!/usr/bin/env python3
"""Measure MI Academy local release artifacts.

This is intentionally file-system based: it records the size of artifacts that
were actually built on this machine instead of inferring readiness from source.
"""

from __future__ import annotations

import argparse
import json
from dataclasses import asdict, dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
MOBILE = ROOT / "apps" / "mobile"
APK = MOBILE / "build" / "app" / "outputs" / "flutter-apk" / "app-debug.apk"
WEB = MOBILE / "build" / "web"


@dataclass
class Artifact:
    path: str
    exists: bool
    bytes: int
    mib: float


@dataclass
class PerformanceBaseline:
    android_debug_apk: Artifact
    web_build: Artifact
    largest_web_files: list[Artifact]
    thresholds: dict[str, float]
    status: str
    notes: list[str]


def artifact(path: Path) -> Artifact:
    if path.is_file():
        size = path.stat().st_size
    elif path.is_dir():
        size = sum(p.stat().st_size for p in path.rglob("*") if p.is_file())
    else:
        size = 0
    return Artifact(
        path=str(path.relative_to(ROOT)),
        exists=path.exists(),
        bytes=size,
        mib=round(size / (1024 * 1024), 2),
    )


def largest_web_files(limit: int) -> list[Artifact]:
    if not WEB.exists():
        return []
    files = sorted(
        (p for p in WEB.rglob("*") if p.is_file()),
        key=lambda p: p.stat().st_size,
        reverse=True,
    )
    return [artifact(path) for path in files[:limit]]


def measure(*, require_build: bool = True) -> PerformanceBaseline:
    """Measure build artifact sizes on disk.

    `require_build=True` (the default, used by this tool's own CLI and by
    the CI step that runs immediately after `flutter build`) treats a
    missing artifact as a real failure -- if a build just ran, the output
    should be there.

    `require_build=False` is for callers (e.g. release_evidence.py's
    aggregate ledger) that may run in a context — such as a checkout that
    never runs `flutter build` at all, like the backend-only python-tests
    CI job — where "no artifact" doesn't mean "the build broke," it means
    "nothing was built here." Conflating those two cases previously made
    this gate's pass/fail outcome depend on incidental local build state
    (e.g. a stale APK left over from an earlier manual build) rather than
    anything this ledger itself could actually verify.
    """
    apk = artifact(APK)
    web = artifact(WEB)
    thresholds = {
        "android_debug_apk_warn_mib": 200.0,
        "web_build_warn_mib": 50.0,
    }
    notes: list[str] = []
    status = "pass"
    missing_status = "fail" if require_build else "not_built"

    if not apk.exists:
        status = missing_status
        notes.append(
            "Android debug APK is missing; run `flutter build apk --debug`."
            if require_build
            else "Android debug APK was not built in this context (not measured)."
        )
    elif apk.mib > thresholds["android_debug_apk_warn_mib"]:
        status = "warn"
        notes.append("Android debug APK exceeds warning threshold.")

    if not web.exists:
        status = missing_status
        notes.append(
            "Web build is missing; run `flutter build web --release`."
            if require_build
            else "Web build was not built in this context (not measured)."
        )
    elif web.mib > thresholds["web_build_warn_mib"] and status not in {"fail", "not_built"}:
        status = "warn"
        notes.append("Web build exceeds warning threshold.")

    if not notes:
        notes.append("Current local artifact sizes are within warning thresholds.")

    return PerformanceBaseline(
        android_debug_apk=apk,
        web_build=web,
        largest_web_files=largest_web_files(limit=8),
        thresholds=thresholds,
        status=status,
        notes=notes,
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true", help="Print JSON output.")
    args = parser.parse_args()

    result = measure()
    data = asdict(result)
    if args.json:
      print(json.dumps(data, indent=2, ensure_ascii=False))
    else:
      print(f"Status: {result.status}")
      print(f"Android debug APK: {result.android_debug_apk.mib} MiB")
      print(f"Web build: {result.web_build.mib} MiB")
      print("Largest web files:")
      for item in result.largest_web_files:
          print(f"  {item.path}: {item.mib} MiB")
      for note in result.notes:
          print(f"Note: {note}")
    return 0 if result.status in {"pass", "warn"} else 1


if __name__ == "__main__":
    raise SystemExit(main())
