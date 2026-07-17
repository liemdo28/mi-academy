#!/usr/bin/env python3
"""Audit mobile platform privacy surfaces for MI Academy.

This is a release-preflight check for the child-safe product promises:
no ads, no in-app purchases, no social integrations, no tracking prompts, and
no sensitive device permissions. It scans platform manifests and dependency
metadata, separate from the Dart game/source audits.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import asdict, dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
MOBILE = ROOT / "apps" / "mobile"


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


ANDROID_FAIL_PERMISSIONS = {
    "android.permission.CAMERA": "Camera access is not needed for the MVP child app.",
    "android.permission.RECORD_AUDIO": "Microphone access is not needed for the MVP child app.",
    "android.permission.ACCESS_FINE_LOCATION": "Precise location is not allowed.",
    "android.permission.ACCESS_COARSE_LOCATION": "Location is not allowed.",
    "android.permission.READ_CONTACTS": "Contacts access is not allowed.",
    "android.permission.WRITE_CONTACTS": "Contacts access is not allowed.",
    "android.permission.READ_PHONE_STATE": "Phone-state access is not allowed.",
    "android.permission.QUERY_ALL_PACKAGES": "Broad package visibility is not allowed.",
    "com.google.android.gms.permission.AD_ID": "Advertising ID access is not allowed.",
}

ANDROID_WARN_PERMISSIONS = {
    "android.permission.INTERNET": "Internet permission must remain parent/sync/backend only and offline-first.",
}

IOS_FAIL_KEYS = {
    "NSCameraUsageDescription": "Camera prompt is not allowed for MVP.",
    "NSMicrophoneUsageDescription": "Microphone prompt is not allowed for MVP.",
    "NSLocationWhenInUseUsageDescription": "Location prompt is not allowed.",
    "NSLocationAlwaysAndWhenInUseUsageDescription": "Location prompt is not allowed.",
    "NSContactsUsageDescription": "Contacts prompt is not allowed.",
    "NSUserTrackingUsageDescription": "App tracking prompt is not allowed.",
    "SKAdNetworkItems": "Ad attribution configuration is not allowed.",
}

DEPENDENCY_FAIL_PATTERNS = {
    r"\bgoogle_mobile_ads\b": "Advertising SDK is not allowed.",
    r"\bfirebase_admob\b": "Advertising SDK is not allowed.",
    r"\bfacebook_audience_network\b": "Advertising SDK is not allowed.",
    r"\bin_app_purchase\b": "In-app purchase SDK is not allowed.",
    r"\bpurchases_flutter\b": "Subscription or purchase SDK is not allowed.",
    r"\bstore_kit_wrappers\b": "StoreKit purchase wrapper is not allowed.",
    r"\bflutter_facebook_auth\b": "Social sign-in is not allowed.",
    r"\bgoogle_sign_in\b": "Social sign-in is not allowed for children.",
    r"\bfirebase_analytics\b": "Behavioral analytics requires privacy review.",
    r"\bappsflyer|adjust_sdk|branch_sdk\b": "Attribution/tracking SDK is not allowed.",
}

GRADLE_FAIL_PATTERNS = {
    r"com\.google\.android\.gms:play-services-ads": "Google ads dependency is not allowed.",
    r"com\.android\.billingclient": "Billing client is not allowed.",
    r"facebook.*audience": "Audience network dependency is not allowed.",
}


def iter_files() -> list[Path]:
    candidates = [
        MOBILE / "pubspec.yaml",
        MOBILE / "pubspec.lock",
        MOBILE / "android" / "app" / "build.gradle.kts",
        MOBILE / "android" / "build.gradle.kts",
        MOBILE / "android" / "app" / "src" / "main" / "AndroidManifest.xml",
        MOBILE / "android" / "app" / "src" / "debug" / "AndroidManifest.xml",
        MOBILE / "android" / "app" / "src" / "profile" / "AndroidManifest.xml",
        MOBILE / "ios" / "Runner" / "Info.plist",
        MOBILE / "ios" / "Podfile.lock",
    ]
    return [path for path in candidates if path.exists()]


def add_finding(
    findings: list[Finding],
    *,
    severity: str,
    category: str,
    path: Path,
    line: int,
    match: str,
    note: str,
) -> None:
    try:
        display_path = str(path.relative_to(ROOT))
    except ValueError:
        display_path = path.name
    findings.append(
        Finding(
            severity=severity,
            category=category,
            path=display_path,
            line=line,
            match=match.strip(),
            note=note,
        )
    )


def scan_file(path: Path, findings: list[Finding]) -> None:
    text = path.read_text(encoding="utf-8", errors="replace")
    for line_no, line in enumerate(text.splitlines(), start=1):
        if path.name == "AndroidManifest.xml":
            scan_android_line(path, line_no, line, findings)
        elif path.name == "Info.plist":
            scan_ios_line(path, line_no, line, findings)
        elif path.suffix in {".yaml", ".lock"}:
            scan_dependency_line(path, line_no, line, findings)
        elif "gradle" in path.name:
            scan_gradle_line(path, line_no, line, findings)


def scan_android_line(
    path: Path, line_no: int, line: str, findings: list[Finding]
) -> None:
    for permission, note in ANDROID_FAIL_PERMISSIONS.items():
        if permission in line:
            add_finding(
                findings,
                severity="fail",
                category="android_permission",
                path=path,
                line=line_no,
                match=permission,
                note=note,
            )
    for permission, note in ANDROID_WARN_PERMISSIONS.items():
        if permission in line:
            normalized = path.as_posix()
            severity = (
                "warn"
                if "src/debug" in normalized or "src/profile" in normalized
                else "fail"
            )
            add_finding(
                findings,
                severity=severity,
                category="android_permission",
                path=path,
                line=line_no,
                match=permission,
                note=note,
            )


def scan_ios_line(path: Path, line_no: int, line: str, findings: list[Finding]) -> None:
    for key, note in IOS_FAIL_KEYS.items():
        if key in line:
            add_finding(
                findings,
                severity="fail",
                category="ios_privacy_key",
                path=path,
                line=line_no,
                match=key,
                note=note,
            )


def scan_dependency_line(
    path: Path, line_no: int, line: str, findings: list[Finding]
) -> None:
    for pattern, note in DEPENDENCY_FAIL_PATTERNS.items():
        if re.search(pattern, line, flags=re.IGNORECASE):
            add_finding(
                findings,
                severity="fail",
                category="dependency",
                path=path,
                line=line_no,
                match=line,
                note=note,
            )


def scan_gradle_line(path: Path, line_no: int, line: str, findings: list[Finding]) -> None:
    for pattern, note in GRADLE_FAIL_PATTERNS.items():
        if re.search(pattern, line, flags=re.IGNORECASE):
            add_finding(
                findings,
                severity="fail",
                category="dependency",
                path=path,
                line=line_no,
                match=line,
                note=note,
            )


def audit() -> AuditResult:
    findings: list[Finding] = []
    files = iter_files()
    for path in files:
        scan_file(path, findings)

    fail_count = sum(1 for finding in findings if finding.severity == "fail")
    warn_count = sum(1 for finding in findings if finding.severity == "warn")
    return AuditResult(
        status="fail" if fail_count else "pass",
        scanned_files=len(files),
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
        print(f"Scanned files: {result.scanned_files}")
        print(f"Failures: {result.summary['fail']}")
        print(f"Warnings: {result.summary['warn']}")
        for finding in result.findings:
            print(
                f"[{finding.severity.upper()}] {finding.path}:{finding.line} "
                f"{finding.category} - {finding.note}"
            )
    return 0 if result.status == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
