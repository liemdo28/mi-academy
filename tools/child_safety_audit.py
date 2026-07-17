#!/usr/bin/env python3
"""Static child-safety/privacy audit for MI Academy mobile.

The audit is intentionally conservative and source-scoped. It checks the
mobile app source, pubspec, and platform manifests for features the product
brief forbids: ads, in-app purchases, social integrations, external-link
launching, sensitive permissions, and pressure/dark-pattern wording.
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


PROHIBITED_DEPENDENCIES = {
    "google_mobile_ads": "Advertising SDK is not allowed.",
    "firebase_admob": "Advertising SDK is not allowed.",
    "facebook_audience_network": "Advertising SDK is not allowed.",
    "in_app_purchase": "In-app purchase SDK is not allowed.",
    "purchases_flutter": "Subscription/purchase SDK is not allowed.",
    "url_launcher": "External-link launcher is not allowed in child-facing app.",
    "google_sign_in": "Social/external sign-in is not allowed for children.",
    "flutter_facebook_auth": "Social sign-in is not allowed.",
    "firebase_analytics": "Behavioral analytics requires privacy review.",
}

WARNING_DEPENDENCIES = {
    "dio": "Network client dependency present; verify parent/sync/backend use only.",
    "connectivity_plus": "Connectivity dependency present; verify offline-first behavior.",
}

PROHIBITED_SOURCE_PATTERNS = {
    r"\bAdWidget\b|\bRewardedAd\b|\bInterstitialAd\b|\bBannerAd\b": (
        "advertising",
        "Ad widget or rewarded/interstitial/banner ad API detected.",
    ),
    r"\bInAppPurchase\b|\bPurchaseParam\b|\bProductDetails\b": (
        "in_app_purchase",
        "In-app purchase API detected.",
    ),
    r"\blaunchUrl\b|\bcanLaunchUrl\b|\burl_launcher\b": (
        "external_links",
        "External URL launcher detected.",
    ),
    r"\bFacebook\b|\bGoogleSignIn\b|\bfriend request\b|\bleaderboard\b": (
        "social",
        "Social/login/leaderboard feature detected.",
    ),
    r"\b(advertisingIdentifier|IDFA|AAID)\b": (
        "tracking",
        "Advertising identifier access detected.",
    ),
    r"\b(lost your streak|lose progress|come back tomorrow|countdown pressure)\b": (
        "pressure",
        "Pressure or loss-aversion wording detected.",
    ),
    r"\b(wrong!|sai rồi|fail(ed)?|you lost)\b": (
        "feedback",
        "Potentially harsh failure wording detected.",
    ),
}

SENSITIVE_ANDROID_PERMISSIONS = {
    "android.permission.CAMERA",
    "android.permission.RECORD_AUDIO",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.READ_CONTACTS",
    "android.permission.WRITE_CONTACTS",
    "android.permission.READ_PHONE_STATE",
    "android.permission.QUERY_ALL_PACKAGES",
    "com.google.android.gms.permission.AD_ID",
}

SENSITIVE_IOS_KEYS = {
    "NSCameraUsageDescription",
    "NSMicrophoneUsageDescription",
    "NSLocationWhenInUseUsageDescription",
    "NSLocationAlwaysAndWhenInUseUsageDescription",
    "NSContactsUsageDescription",
    "NSUserTrackingUsageDescription",
}

WARNING_SOURCE_PATTERNS = {
    r"https?://": (
        "network",
        "Network URL detected; verify it is parent/sync/backend only and not a child-facing external link.",
    ),
}


def iter_files() -> list[Path]:
    roots = [
        MOBILE / "pubspec.yaml",
        MOBILE / "lib",
        MOBILE / "android" / "app" / "src" / "main" / "AndroidManifest.xml",
        MOBILE / "ios" / "Runner" / "Info.plist",
    ]
    files: list[Path] = []
    for root in roots:
        if root.is_file():
            files.append(root)
        elif root.is_dir():
            files.extend(
                p
                for p in root.rglob("*")
                if p.is_file() and p.suffix in {".dart", ".yaml", ".xml", ".plist"}
            )
    return sorted(files)


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
    findings.append(
        Finding(
            severity=severity,
            category=category,
            path=str(path.relative_to(ROOT)),
            line=line,
            match=match.strip(),
            note=note,
        )
    )


def scan_pubspec(path: Path, text: str, findings: list[Finding]) -> None:
    for line_no, line in enumerate(text.splitlines(), start=1):
        dep_match = re.match(r"\s{2}([a-zA-Z0-9_]+):", line)
        if not dep_match:
            continue
        package = dep_match.group(1)
        if package in PROHIBITED_DEPENDENCIES:
            add_finding(
                findings,
                severity="fail",
                category="dependency",
                path=path,
                line=line_no,
                match=package,
                note=PROHIBITED_DEPENDENCIES[package],
            )
        if package in WARNING_DEPENDENCIES:
            add_finding(
                findings,
                severity="warn",
                category="network",
                path=path,
                line=line_no,
                match=package,
                note=WARNING_DEPENDENCIES[package],
            )


def scan_android_manifest(path: Path, text: str, findings: list[Finding]) -> None:
    for line_no, line in enumerate(text.splitlines(), start=1):
        for permission in SENSITIVE_ANDROID_PERMISSIONS:
            if permission in line:
                add_finding(
                    findings,
                    severity="fail",
                    category="permission",
                    path=path,
                    line=line_no,
                    match=permission,
                    note="Sensitive Android permission is not allowed for MVP child app.",
                )
        if "android.permission.INTERNET" in line:
            add_finding(
                findings,
                severity="warn",
                category="network",
                path=path,
                line=line_no,
                match="android.permission.INTERNET",
                note="Internet permission requires offline-first and child-facing network review.",
            )


def scan_ios_plist(path: Path, text: str, findings: list[Finding]) -> None:
    for line_no, line in enumerate(text.splitlines(), start=1):
        for key in SENSITIVE_IOS_KEYS:
            if key in line:
                add_finding(
                    findings,
                    severity="fail",
                    category="permission",
                    path=path,
                    line=line_no,
                    match=key,
                    note="Sensitive iOS permission/tracking prompt is not allowed for MVP child app.",
                )


def scan_source(path: Path, text: str, findings: list[Finding]) -> None:
    for line_no, line in enumerate(text.splitlines(), start=1):
        stripped = line.strip()
        comment_only = stripped.startswith(("//", "///", "<!--"))
        for pattern, (category, note) in PROHIBITED_SOURCE_PATTERNS.items():
            if re.search(pattern, line, flags=re.IGNORECASE):
                add_finding(
                    findings,
                    severity="fail",
                    category=category,
                    path=path,
                    line=line_no,
                    match=line,
                    note=note,
                )
        if path.suffix in {".xml", ".plist"}:
            continue
        if comment_only:
            continue
        for pattern, (category, note) in WARNING_SOURCE_PATTERNS.items():
            if re.search(pattern, line, flags=re.IGNORECASE):
                add_finding(
                    findings,
                    severity="warn",
                    category=category,
                    path=path,
                    line=line_no,
                    match=line,
                    note=note,
                )


def audit() -> AuditResult:
    findings: list[Finding] = []
    files = iter_files()
    for path in files:
        text = path.read_text(encoding="utf-8", errors="replace")
        if path.name == "pubspec.yaml":
            scan_pubspec(path, text, findings)
        elif path.name == "AndroidManifest.xml":
            scan_android_manifest(path, text, findings)
        elif path.name == "Info.plist":
            scan_ios_plist(path, text, findings)
        scan_source(path, text, findings)

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
