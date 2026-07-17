#!/usr/bin/env python3
"""Collect local release evidence for MI Academy.

This ledger is intentionally truth-first: it records local automated gates,
keeps production blockers visible, and leaves external/manual proof as pending
instead of inferring release readiness from source-only checks.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from dataclasses import asdict, dataclass
from datetime import date
from pathlib import Path
from typing import Callable

ROOT = Path(__file__).resolve().parent.parent
REPORT_PATH = ROOT / "docs" / "qa" / "RELEASE_EVIDENCE_2026-07-17.md"

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools import (  # noqa: E402
    child_safety_audit,
    child_safety_signoff,
    content_safety_audit,
    game_network_audit,
    mobile_platform_privacy_audit,
    performance_baseline,
    production_audio_audit,
)


@dataclass
class GateEvidence:
    gate: str
    status: str
    source: str
    summary: str
    evidence: str
    required_for_release: bool


@dataclass
class ReleaseEvidence:
    status: str
    generated_on: str
    local_gates: list[GateEvidence]
    pending_external_gates: list[GateEvidence]
    blockers: list[str]


def run_command(args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        args,
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )


def build_report(
    command_runner: Callable[[list[str]], subprocess.CompletedProcess[str]] = run_command,
) -> ReleaseEvidence:
    local_gates = [
        _command_gate(
            "Content validation",
            [sys.executable, "tools/content_validator/validate_content.py"],
            command_runner,
            pass_summary="All bundled MVP content and placeholder audio references are valid.",
        ),
        _command_gate(
            "Level solvability",
            [sys.executable, "tools/level_validator/solve_levels.py"],
            command_runner,
            pass_summary="All six MVP game level sets are solvable.",
        ),
        _content_safety_gate(),
        _game_network_gate(),
        _static_child_safety_gate(),
        _platform_privacy_gate(),
        _child_safety_presignoff_gate(),
        _performance_artifact_gate(),
        _production_audio_gate(),
    ]
    pending_external_gates = _pending_external_gates()
    blockers = [
        f"{gate.gate}: {gate.summary}"
        for gate in local_gates + pending_external_gates
        if gate.required_for_release and gate.status in {"fail", "blocked", "pending"}
    ]
    if any(gate.status == "fail" for gate in local_gates):
        status = "fail"
    elif blockers:
        status = "blocked"
    else:
        status = "pass"
    return ReleaseEvidence(
        status=status,
        generated_on=date.today().isoformat(),
        local_gates=local_gates,
        pending_external_gates=pending_external_gates,
        blockers=blockers,
    )


def write_markdown(report: ReleaseEvidence, path: Path = REPORT_PATH) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(render_markdown(report), encoding="utf-8")


def render_markdown(report: ReleaseEvidence) -> str:
    lines = [
        "# MI Academy - Release Evidence Ledger",
        "",
        f"> **Generated:** {report.generated_on}",
        f"> **Status:** {report.status}",
        "",
        "This ledger summarizes automated local evidence and the remaining proof required before release. It does not replace manual QA, real-device testing, deployed API verification, or remote CI evidence.",
        "",
        "## Local Automated Gates",
        "",
        "| Gate | Status | Source | Summary |",
        "|------|--------|--------|---------|",
    ]
    for gate in report.local_gates:
        lines.append(
            f"| {gate.gate} | {gate.status} | `{gate.source}` | {gate.summary} |"
        )

    lines.extend(
        [
            "",
            "## Pending External Evidence",
            "",
            "| Gate | Status | Evidence required |",
            "|------|--------|-------------------|",
        ]
    )
    for gate in report.pending_external_gates:
        lines.append(f"| {gate.gate} | {gate.status} | {gate.evidence} |")

    lines.extend(["", "## Release Blockers", ""])
    for blocker in report.blockers:
        lines.append(f"- {blocker}")
    if not report.blockers:
        lines.append("- None recorded by this ledger.")
    return "\n".join(lines).rstrip() + "\n"


def _command_gate(
    gate: str,
    command: list[str],
    command_runner: Callable[[list[str]], subprocess.CompletedProcess[str]],
    *,
    pass_summary: str,
) -> GateEvidence:
    result = command_runner(command)
    status = "pass" if result.returncode == 0 else "fail"
    evidence = _last_meaningful_line(result.stdout) or _last_meaningful_line(result.stderr)
    summary = pass_summary if status == "pass" else evidence or "Command failed."
    return GateEvidence(
        gate=gate,
        status=status,
        source=" ".join(_display_arg(part) for part in command),
        summary=summary,
        evidence=evidence,
        required_for_release=True,
    )


def _content_safety_gate() -> GateEvidence:
    result = content_safety_audit.audit()
    return GateEvidence(
        gate="Content safety audit",
        status=result.status,
        source="tools/content_safety_audit.py --json",
        summary=(
            f"{result.files_scanned} files, {result.strings_scanned} strings, "
            f"{result.summary['fail']} failures, {result.summary['warn']} warnings."
        ),
        evidence="Authored child-facing text and metadata scanned for links, purchases, social pressure, harsh feedback, privacy requests, and countdown pressure.",
        required_for_release=True,
    )


def _game_network_gate() -> GateEvidence:
    result = game_network_audit.audit()
    return GateEvidence(
        gate="Game offline-only audit",
        status=result.status,
        source="tools/game_network_audit.py --json",
        summary=(
            f"{result.scanned_files} game Dart files, "
            f"{result.summary['fail']} failures."
        ),
        evidence="Child-facing game code scanned for network clients, URLs, launchers, and webviews.",
        required_for_release=True,
    )


def _static_child_safety_gate() -> GateEvidence:
    result = child_safety_audit.audit()
    return GateEvidence(
        gate="Static child-safety audit",
        status=result.status,
        source="tools/child_safety_audit.py --json",
        summary=(
            f"{result.scanned_files} files, {result.summary['fail']} failures, "
            f"{result.summary['warn']} expected warnings."
        ),
        evidence="Mobile source, pubspec, and manifests scanned for forbidden child-safety and privacy surfaces.",
        required_for_release=True,
    )


def _platform_privacy_gate() -> GateEvidence:
    result = mobile_platform_privacy_audit.audit()
    return GateEvidence(
        gate="Mobile platform privacy audit",
        status=result.status,
        source="tools/mobile_platform_privacy_audit.py --json",
        summary=(
            f"{result.scanned_files} files, {result.summary['fail']} failures, "
            f"{result.summary['warn']} debug/profile Internet warnings."
        ),
        evidence="Android/iOS manifests and dependency metadata scanned for sensitive permissions, tracking prompts, ads, IAP, and social SDKs.",
        required_for_release=True,
    )


def _child_safety_presignoff_gate() -> GateEvidence:
    result = child_safety_signoff.build_report()
    pending_count = sum(1 for game in result.games if game.manual_status == "pending")
    return GateEvidence(
        gate="Child-safety pre-signoff",
        status=result.status,
        source="tools/child_safety_signoff.py --json",
        summary=(
            f"{len(result.games)} MVP games have automated pass evidence; "
            f"{pending_count} manual game reviews remain pending."
        ),
        evidence="Automated per-game safety matrix generated; human/device review is still required.",
        required_for_release=True,
    )


def _performance_artifact_gate() -> GateEvidence:
    # require_build=False: this ledger may run in a context (e.g. the
    # backend-only python-tests CI job) that never runs `flutter build` at
    # all, where a missing artifact means "not measured here" rather than
    # "the build broke." See performance_baseline.measure()'s docstring.
    result = performance_baseline.measure(require_build=False)
    return GateEvidence(
        gate="Artifact-size baseline",
        status=result.status,
        source="tools/performance_baseline.py --json",
        summary=(
            f"Android debug APK {result.android_debug_apk.mib} MiB; "
            f"web build {result.web_build.mib} MiB."
        ),
        evidence="Local build artifact sizes measured from files on disk; runtime FPS/memory/cold-start still require device proof.",
        required_for_release=False,
    )


def _production_audio_gate() -> GateEvidence:
    result = production_audio_audit.audit()
    status = "pass" if result.status == "pass" else "blocked"
    return GateEvidence(
        gate="Production audio audit",
        status=status,
        source="tools/production_audio_audit.py --json",
        summary=(
            f"{result.assets_scanned} assets, {result.placeholder_assets} placeholders, "
            f"{result.approved_assets} approved, {result.summary['fail']} failures."
        ),
        evidence="Every release audio asset must be non-placeholder, non-empty, approved, and attributed to a real speaker/source.",
        required_for_release=True,
    )


def _pending_external_gates() -> list[GateEvidence]:
    return [
        _pending_gate(
            "Manual per-game child-safety sign-off",
            "Completed human checklist for all six MVP games on a real device or emulator, attached to the release PR.",
        ),
        _pending_gate(
            "Real device/emulator smoke test",
            "Recorded Android/iOS run covering app launch, all six MVP games, parent gate, offline mode, and no child-facing network requirement.",
        ),
        _pending_gate(
            "Runtime performance proof",
            "Device or emulator measurements for cold start, game load, frame timing, memory, save latency, and restore latency.",
        ),
        _pending_gate(
            "Deployed parent API verification",
            "Live API proof for parent reports, weekly report, privacy-safe export, and child-data deletion.",
        ),
        _pending_gate(
            "Deployed backend/device offline sync",
            "A real queued offline play session syncing progress, attempts, and session summaries to a deployed backend.",
        ),
        _pending_gate(
            "Real-device accessibility audit",
            "Screen reader, touch target, reduced motion, contrast, subtitle, and non-drag alternative checks on target devices.",
        ),
        _pending_gate(
            "Remote GitHub Actions release workflow",
            "Successful remote workflow run URL including content/safety gates, Python tests, mobile builds, artifacts, and iOS no-codesign build.",
        ),
    ]


def _pending_gate(gate: str, evidence: str) -> GateEvidence:
    return GateEvidence(
        gate=gate,
        status="pending",
        source="external/manual",
        summary="Evidence not present in the local workspace.",
        evidence=evidence,
        required_for_release=True,
    )


def _last_meaningful_line(text: str) -> str:
    for line in reversed(text.splitlines()):
        stripped = line.strip()
        if stripped:
            return stripped
    return ""


def _display_arg(arg: str) -> str:
    try:
        path = Path(arg)
        if path.is_absolute():
            return path.name
    except OSError:
        pass
    return arg


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
