#!/usr/bin/env python3
"""Localization audit for MI Academy mobile.

Two independent checks:

1. Translation-key parity between packages/localization/lib/l10n's VI/EN
   .arb files -- this is a hard gate (nonzero exit on mismatch) since a
   missing key is a real, fixable bug, not a work-in-progress finding.
2. A best-effort scan for hardcoded Vietnamese-diacritic string literals
   in apps/mobile/lib -- this is report-only (always exits 0 on its own;
   only --fail-on-hardcoded makes it a gate). Retrofitting every flagged
   site to use real localization is tracked as an open, multi-file effort
   (see docs/release-audit.md RA-05) rather than something this scan can
   safely auto-fix or block CI on today.

Deliberately excluded from the hardcoded-string scan: test files
(`apps/mobile/test/**`), generated/build directories, and this tool's own
fixtures -- flagging Vietnamese text used deliberately in a test's expected
output is noise, not a finding.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path

# Vietnamese output on a non-UTF-8 console (e.g. Windows' legacy cp1252)
# would otherwise crash with UnicodeEncodeError -- this tool's whole
# purpose is reporting Vietnamese text, so it must be able to print it
# anywhere it runs, not just on CI's UTF-8 Linux runners.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parent.parent
L10N_DIR = ROOT / "packages" / "localization" / "lib" / "l10n"
MOBILE_LIB = ROOT / "apps" / "mobile" / "lib"

# Vietnamese-diacritic Unicode ranges (Latin Extended Additional block plus
# the handful of combining/precomposed vowels outside it) -- a string
# containing one of these is almost certainly Vietnamese prose, not an
# identifier, icon glyph, or asset path.
_VIETNAMESE_CHAR_RE = re.compile(r"[À-ỹ]")
_STRING_LITERAL_RE = re.compile(r"'((?:[^'\\]|\\.)*)'|\"((?:[^\"\\]|\\.)*)\"")

_EXCLUDED_DIR_NAMES = {"test", ".dart_tool", "build"}


@dataclass
class ParityResult:
    status: str
    en_key_count: int
    vi_key_count: int
    missing_in_en: list[str]
    missing_in_vi: list[str]


@dataclass
class HardcodedStringFinding:
    path: str
    line: int
    snippet: str


@dataclass
class ScanResult:
    status: str
    files_scanned: int
    findings: list[HardcodedStringFinding]


def check_arb_parity() -> ParityResult:
    en_path = L10N_DIR / "app_en.arb"
    vi_path = L10N_DIR / "app_vi.arb"
    en_data = json.loads(en_path.read_text(encoding="utf-8"))
    vi_data = json.loads(vi_path.read_text(encoding="utf-8"))

    en_keys = {k for k in en_data if not k.startswith("@")}
    vi_keys = {k for k in vi_data if not k.startswith("@")}

    missing_in_en = sorted(vi_keys - en_keys)
    missing_in_vi = sorted(en_keys - vi_keys)
    status = "pass" if not missing_in_en and not missing_in_vi else "fail"

    return ParityResult(
        status=status,
        en_key_count=len(en_keys),
        vi_key_count=len(vi_keys),
        missing_in_en=missing_in_en,
        missing_in_vi=missing_in_vi,
    )


def _is_excluded(path: Path) -> bool:
    return any(part in _EXCLUDED_DIR_NAMES for part in path.parts)


def scan_hardcoded_strings() -> ScanResult:
    findings: list[HardcodedStringFinding] = []
    files_scanned = 0

    for dart_file in sorted(MOBILE_LIB.rglob("*.dart")):
        if _is_excluded(dart_file.relative_to(ROOT)):
            continue
        files_scanned += 1
        for line_num, line in enumerate(
            dart_file.read_text(encoding="utf-8").splitlines(), start=1
        ):
            stripped = line.strip()
            if stripped.startswith("//") or stripped.startswith("///"):
                continue  # comments aren't user-facing strings
            for match in _STRING_LITERAL_RE.finditer(line):
                literal = match.group(1) or match.group(2) or ""
                if _VIETNAMESE_CHAR_RE.search(literal):
                    findings.append(
                        HardcodedStringFinding(
                            path=str(dart_file.relative_to(ROOT)),
                            line=line_num,
                            snippet=literal[:80],
                        )
                    )
                    break  # one finding per line is enough signal

    return ScanResult(
        status="pass" if not findings else "warn",
        files_scanned=files_scanned,
        findings=findings,
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--json", action="store_true", help="Emit machine-readable JSON."
    )
    parser.add_argument(
        "--fail-on-hardcoded",
        action="store_true",
        help="Exit nonzero if any hardcoded Vietnamese string is found "
        "(off by default -- see module docstring).",
    )
    args = parser.parse_args()

    parity = check_arb_parity()
    scan = scan_hardcoded_strings()

    if args.json:
        print(
            json.dumps(
                {"parity": asdict(parity), "hardcoded_scan": asdict(scan)},
                indent=2,
                ensure_ascii=False,
            )
        )
    else:
        print(
            f"[{parity.status.upper()}] arb parity: "
            f"{parity.en_key_count} en keys, {parity.vi_key_count} vi keys"
        )
        if parity.missing_in_en:
            print(f"  missing in en: {parity.missing_in_en}")
        if parity.missing_in_vi:
            print(f"  missing in vi: {parity.missing_in_vi}")
        print(
            f"[{scan.status.upper()}] hardcoded-string scan: "
            f"{scan.files_scanned} files scanned, {len(scan.findings)} "
            "hardcoded Vietnamese string(s) found"
        )
        for finding in scan.findings[:20]:
            print(f"  {finding.path}:{finding.line}: {finding.snippet!r}")
        if len(scan.findings) > 20:
            print(f"  ... and {len(scan.findings) - 20} more")

    if parity.status == "fail":
        return 1
    if args.fail_on_hardcoded and scan.findings:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
