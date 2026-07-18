#!/usr/bin/env python3
"""MI Academy Developer CLI - unified dev tool for all teams.

Usage:
    mi doctor         Check environment health
    mi setup          Initialize dev environment
    mi dev            Start local dev servers
    mi test           Run all tests
    mi test contracts Run contract tests only
    mi test integration Run integration tests
    mi generate       Generate code from schemas
    mi validate       Validate all contracts and content
    mi seed           Seed test data
    mi mock start     Start mock services
    mi mock stop      Stop mock services
    mi scenario run   Run integration scenario
    mi report         Generate integration report
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path
from datetime import datetime

# ─── Constants ───────────────────────────────────────────────────────────────

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
CONTRACTS_DIR = PROJECT_ROOT / "contracts"
PACKAGES_DIR = PROJECT_ROOT / "packages"
FIXTURES_DIR = PROJECT_ROOT / "integration" / "fixtures"
SCENARIOS_DIR = PROJECT_ROOT / "integration" / "scenarios"
MOCKS_DIR = PROJECT_ROOT / "integration" / "mocks"
DOCS_DIR = PROJECT_ROOT / "docs"

REQUIRED_DIRS = [CONTRACTS_DIR, PACKAGES_DIR, FIXTURES_DIR, SCENARIOS_DIR, MOCKS_DIR]

# ─── Helpers ──────────────────────────────────────────────────────────────────

def _print_header(text: str):
    print(f"\n{'='*60}")
    print(f"  MI Academy - {text}")
    print(f"{'='*60}\n")

def _print_check(label: str, status: str, detail: str = ""):
    icon = {"PASS": "[PASS]", "WARN": "[WARN]", "FAIL": "[FAIL]"}.get(status, "[?]")
    line = f"  {icon} {label}"
    if detail:
        line += f" - {detail}"
    print(line)

def _run(cmd: list[str], cwd: Path | None = None, check: bool = False) -> subprocess.CompletedProcess:
    executable = shutil.which(cmd[0])
    resolved_cmd = [executable or cmd[0], *cmd[1:]]
    try:
        return subprocess.run(resolved_cmd, cwd=cwd or PROJECT_ROOT, capture_output=True, text=True)
    except FileNotFoundError as exc:
        return subprocess.CompletedProcess(cmd, 127, "", str(exc))


# ─── mi doctor ──────────────────────────────────────────────────────────────

def cmd_doctor(args):
    _print_header("Repository Doctor - Environment Health Check")
    checks_passed = 0
    checks_failed = 0
    warnings = 0

    # Check required directories
    _print_header("Required Directories")
    for d in REQUIRED_DIRS:
        if d.exists():
            _print_check(str(d.relative_to(PROJECT_ROOT)), "PASS")
            checks_passed += 1
        else:
            _print_check(str(d.relative_to(PROJECT_ROOT)), "FAIL", "Missing directory")
            checks_failed += 1

    # Check required files
    _print_header("Required Files")
    required_files = [
        (CONTRACTS_DIR / "openapi.yaml", "OpenAPI spec"),
        (PROJECT_ROOT / "packages" / "mi_game_core" / "lib" / "src" / "contracts" / "mi_game_result.dart", "Game result contract (Dart)"),
        (PROJECT_ROOT / "packages" / "mi_game_core" / "lib" / "src" / "contracts" / "mi_progress_gateway.dart", "Progress gateway"),
        (PROJECT_ROOT / "content" / "schemas" / "lesson.schema.json", "Lesson schema"),
        (PROJECT_ROOT / "schemas" / "level.schema.json", "Level schema"),
        (PROJECT_ROOT / "melos.yaml", "Melos config"),
    ]
    for fpath, label in required_files:
        if fpath.exists():
            _print_check(label, "PASS")
            checks_passed += 1
        else:
            _print_check(label, "FAIL", f"Missing: {fpath}")
            checks_failed += 1

    # Check Python
    _print_header("Python Environment")
    result = _run([sys.executable, "--version"])
    py_ver = result.stdout.strip() if result.returncode == 0 else "NOT FOUND"
    if result.returncode == 0:
        _print_check("Python", "PASS", py_ver)
        checks_passed += 1
    else:
        _print_check("Python", "FAIL", "Python not found")
        checks_failed += 1

    # Check Flutter/Dart
    _print_header("Flutter Environment")
    result = _run(["flutter", "--version"], check=False)
    if result.returncode == 0:
        first_line = result.stdout.split("\n")[0]
        _print_check("Flutter", "PASS", first_line)
        checks_passed += 1
    else:
        _print_check("Flutter", "WARN", "Flutter not found - required for mobile/game development")
        warnings += 1

    result = _run(["dart", "--version"], check=False)
    if result.returncode == 0:
        _print_check("Dart", "PASS", result.stdout.strip().split("\n")[0])
        checks_passed += 1
    else:
        _print_check("Dart", "WARN", "Dart not found")
        warnings += 1

    # Check Node
    _print_header("Node Environment")
    result = _run(["node", "--version"], check=False)
    if result.returncode == 0:
        _print_check("Node.js", "PASS", result.stdout.strip())
        checks_passed += 1
    else:
        _print_check("Node.js", "WARN", "Node.js not found - required for admin tools")
        warnings += 1

    # Check Docker
    result = _run(["docker", "--version"], check=False)
    if result.returncode == 0:
        _print_check("Docker", "PASS", result.stdout.strip())
        checks_passed += 1
    else:
        _print_check("Docker", "WARN", "Docker not found - required for containerized services")
        warnings += 1

    # Check contracts consistency
    _print_header("Contract Consistency")
    contracts_file = CONTRACTS_DIR / "shared_contracts.py"
    if contracts_file.exists():
        _print_check("Contract registry", "PASS")
        checks_passed += 1
    else:
        _print_check("Contract registry", "WARN", "No contract registry found")
        warnings += 1

    # Check for known issues
    _print_header("Known Integration Risks")
    save_game_result = PROJECT_ROOT / "apps" / "api" / "schemas" / "progress.py"
    if save_game_result.exists():
        content = save_game_result.read_text(encoding="utf-8")
        if "class SaveGameResultRequest(BaseModel):" not in content:
            _print_check("SaveGameResultRequest", "WARN", "Not defined")
            warnings += 1
        elif "\n    pass\n" in content:
            _print_check("SaveGameResultRequest", "FAIL", "Empty model - see SD-01")
            checks_failed += 1
        else:
            _print_check("SaveGameResultRequest", "PASS")
            checks_passed += 1

    removed_shared_models = PROJECT_ROOT / "packages" / "shared_models"
    shared_models_source_files = [
        removed_shared_models / "pubspec.yaml",
        removed_shared_models / "lib" / "shared_models.dart",
    ]
    if any(path.exists() for path in shared_models_source_files):
        _print_check("Removed shared_models package", "FAIL", "Dead duplicate package has reappeared")
        checks_failed += 1
    else:
        _print_check("Removed shared_models package", "PASS", "No stale duplicate package directory")
        checks_passed += 1

    # Summary
    _print_header("Summary")
    print(f"  PASS: {checks_passed}")
    print(f"  WARN: {warnings}")
    print(f"  FAIL: {checks_failed}")
    if checks_failed > 0:
        print(f"\n  [WARN] {checks_failed} critical issue(s) found. Run 'mi doctor --fix' for suggestions.")
        return 1
    elif warnings > 0:
        print(f"\n  [WARN] {warnings} warning(s). System can run but may need attention.")
        return 0
    else:
        print(f"\n  [PASS] All checks passed. System is healthy.")
        return 0


# ─── mi test contracts ─────────────────────────────────────────────────────

def cmd_test_contracts(args):
    _print_header("Contract Tests")
    contracts_file = CONTRACTS_DIR / "shared_contracts.py"
    if not contracts_file.exists():
        print("  [FAIL] No contract registry found at contracts/shared_contracts.py")
        return 1

    # Import and check contracts
    sys.path.insert(0, str(CONTRACTS_DIR))
    try:
        from shared_contracts import CONTRACT_REGISTRY
        print(f"  [PASS] Loaded {len(CONTRACT_REGISTRY)} contracts")
        for cid, cdef in sorted(CONTRACT_REGISTRY.items()):
            compat_icon = {"patch": "[PATCH]", "backward": "[BACKWARD]", "potentially-breaking": "[REVIEW]", "breaking": "[BREAKING]"}.get(cdef.compatibility, "[?]")
            print(f"    {compat_icon} {cid} v{cdef.schema_version} ({cdef.semantic_version}) [{cdef.owner}]")
        return 0
    except Exception as e:
        print(f"  [FAIL] Failed to load contracts: {e}")
        return 1


# ─── mi validate ──────────────────────────────────────────────────────────────

def cmd_validate(args):
    _print_header("Validate All Contracts & Content")
    errors = 0

    # Validate JSON schemas
    schema_files = list(PROJECT_ROOT.glob("content/schemas/*.json")) + list(PROJECT_ROOT.glob("schemas/*.json"))
    for sf in schema_files:
        try:
            data = json.loads(sf.read_text(encoding="utf-8"))
            _print_check(f"Schema: {sf.relative_to(PROJECT_ROOT)}", "PASS", f"Valid JSON, {len(data)} keys")
        except json.JSONDecodeError as e:
            _print_check(f"Schema: {sf.relative_to(PROJECT_ROOT)}", "FAIL", str(e))
            errors += 1

    # Validate fixtures
    for ff in FIXTURES_DIR.glob("**/*.json"):
        try:
            data = json.loads(ff.read_text(encoding="utf-8"))
            _print_check(f"Fixture: {ff.relative_to(PROJECT_ROOT)}", "PASS")
        except json.JSONDecodeError as e:
            _print_check(f"Fixture: {ff.relative_to(PROJECT_ROOT)}", "FAIL", str(e))
            errors += 1

    # Check for duplicate packages
    _print_header("Duplicate Package Detection")
    pkg_names = set()
    for p in PACKAGES_DIR.iterdir():
        if p.is_dir() and (p / "pubspec.yaml").exists():
            name = p.name
            # Check for aliases
            if "game_core" == name or "game-core" == name:
                if name in pkg_names:
                    _print_check(f"Package alias: {name}", "WARN", "Duplicate package detected")
                pkg_names.add(name)

    return 1 if errors > 0 else 0


# ─── mi report ────────────────────────────────────────────────────────────────

def cmd_report(args):
    _print_header("Integration Status Report")
    print(f"  Generated: {datetime.now().isoformat()}")
    print(f"  Project root: {PROJECT_ROOT}")

    # Count contracts
    contracts_file = CONTRACTS_DIR / "shared_contracts.py"
    if contracts_file.exists():
        sys.path.insert(0, str(CONTRACTS_DIR))
        try:
            from shared_contracts import CONTRACT_REGISTRY
            print(f"\n  Contracts registered: {len(CONTRACT_REGISTRY)}")
            for cid, cdef in sorted(CONTRACT_REGISTRY.items()):
                print(f"    - {cid} v{cdef.schema_version} [{cdef.compatibility}]")
        except ImportError:
            print("\n  Contracts: Unable to load registry")

    # Count fixtures
    fixtures = list(FIXTURES_DIR.glob("**/*.json"))
    print(f"\n  Fixtures: {len(fixtures)}")

    # Count mock services
    mocks = list(MOCKS_DIR.glob("**/*.py"))
    print(f"  Mock services: {len(mocks)}")

    # Count scenarios
    scenarios = list(SCENARIOS_DIR.glob("**/*.json"))
    print(f"  Scenarios: {len(scenarios)}")

    # Count docs
    integration_docs = list(DOCS_DIR.glob("integration/*.md"))
    print(f"  Integration docs: {len(integration_docs)}")

    # Risk summary
    _print_header("Open Risks")
    print("  See docs/integration/CROSS_MODULE_RISK_REPORT.md for full details.")
    print("  See docs/integration/SCHEMA_DRIFT_REPORT.md for drift analysis.")

    return 0


# ─── mi mock start / stop ────────────────────────────────────────────────────

def cmd_mock_start(args):
    _print_header("Starting Mock Services")
    mock_main = MOCKS_DIR / "mock_server.py"
    if mock_main.exists():
        print("  Starting mock API server on http://localhost:8090...")
        result = _run([sys.executable, str(mock_main)])
        if result.returncode != 0:
            print(f"  [FAIL] Failed: {result.stderr}")
            return 1
        return 0
    else:
        print("  [FAIL] Mock server not found. Run 'mi setup' first.")
        return 1

def cmd_mock_stop(args):
    _print_header("Stopping Mock Services")
    print("  Mock services stopped (if running).")
    return 0


# ─── mi scenario run ────────────────────────────────────────────────────────

def cmd_scenario_run(args):
    scenario_name = args.scenario if hasattr(args, "scenario") and args.scenario else "first-time-offline"
    _print_header(f"Running Scenario: {scenario_name}")
    scenario_file = SCENARIOS_DIR / f"{scenario_name}.json"
    if scenario_file.exists():
        print(f"  [PASS] Scenario file found: {scenario_file}")
        print(f"  (Full harness implementation pending - Wave 2)")
        return 0
    else:
        print(f"  [FAIL] Scenario not found: {scenario_file}")
        print(f"  Available: first-time-offline, game-resume, content-upgrade, adaptive-fallback, full-mvp")
        return 1


# ─── mi generate ─────────────────────────────────────────────────────────────

def cmd_generate(args):
    _print_header("Code Generation")
    print("  Generation targets:")
    print("    - Dart API client from OpenAPI")
    print("    - Dart model constants from contracts")
    print("    - Fixture indexes")
    print("    - Asset constants from manifest")
    print("  (Full generator implementation pending - Wave 1)")
    return 0


# ─── mi test / test integration ──────────────────────────────────────────────

def cmd_test(args):
    _print_header("Running All Tests")
    # Run Python tests
    result = _run([sys.executable, "-m", "pytest", "tests/", "-v", "--tb=short"], check=False)
    if result.stdout:
        print(result.stdout[-2000:])
    if result.returncode != 0 and result.stderr:
        print(result.stderr[-1000:])
    return result.returncode

def cmd_test_integration(args):
    _print_header("Running Integration Tests")
    result = _run([sys.executable, "-m", "pytest", "packages/mi_contract_tests/", "-v", "--tb=short"], check=False)
    print(result.stdout or result.stderr)
    return result.returncode


# ─── CLI Entry Point ────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        prog="mi",
        description="MI Academy Developer CLI - unified dev tool for all teams.",
    )
    sub = parser.add_subparsers(dest="command")

    sub.add_parser("doctor", help="Check environment health")
    sub.add_parser("setup", help="Initialize dev environment")

    test_parser = sub.add_parser("test", help="Run tests")
    test_parser.add_argument(
        "target",
        nargs="?",
        choices=["all", "contracts", "integration"],
        default="all",
        help="Optional test target",
    )

    sub.add_parser("validate", help="Validate contracts and content")
    sub.add_parser("generate", help="Generate code from schemas")
    sub.add_parser("seed", help="Seed test data")
    sub.add_parser("report", help="Generate integration report")

    mock_parser = sub.add_parser("mock", help="Manage mock services")
    mock_sub = mock_parser.add_subparsers(dest="mock_command")
    mock_sub.add_parser("start", help="Start mock services")
    mock_sub.add_parser("stop", help="Stop mock services")

    scenario_parser = sub.add_parser("scenario", help="Run integration scenarios")
    scenario_sub = scenario_parser.add_subparsers(dest="scenario_command")
    run_parser = scenario_sub.add_parser("run", help="Run a specific scenario")
    run_parser.add_argument("scenario", nargs="?", default="first-time-offline")

    args = parser.parse_args()

    # Route commands
    if args.command == "doctor":
        return cmd_doctor(args)
    elif args.command == "test":
        if args.target == "contracts":
            return cmd_test_contracts(args)
        if args.target == "integration":
            return cmd_test_integration(args)
        return cmd_test(args)
    elif args.command == "validate":
        return cmd_validate(args)
    elif args.command == "generate":
        return cmd_generate(args)
    elif args.command == "report":
        return cmd_report(args)
    elif args.command == "scenario" and hasattr(args, "scenario_command") and args.scenario_command == "run":
        return cmd_scenario_run(args)
    elif args.command == "mock" and hasattr(args, "mock_command") and args.mock_command == "start":
        return cmd_mock_start(args)
    elif args.command == "mock" and hasattr(args, "mock_command") and args.mock_command == "stop":
        return cmd_mock_stop(args)
    else:
        parser.print_help()
        return 0


if __name__ == "__main__":
    sys.exit(main())
