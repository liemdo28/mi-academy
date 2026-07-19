import json

from tools.ci import report_security_scanners


def test_advisory_scanner_findings_are_reported_without_failing(tmp_path):
    pip_report = tmp_path / "pip-audit.json"
    bandit_report = tmp_path / "bandit.json"
    summary = tmp_path / "summary.md"

    pip_report.write_text(
        json.dumps(
            {
                "dependencies": [
                    {
                        "name": "starlette",
                        "vulns": [{"id": "PYSEC-1"}, {"id": "PYSEC-2"}],
                    },
                    {"name": "fastapi", "vulns": []},
                ]
            }
        ),
        encoding="utf-8",
    )
    bandit_report.write_text(json.dumps({"results": []}), encoding="utf-8")

    exit_code = report_security_scanners.main(
        [
            "--pip-audit-report",
            str(pip_report),
            "--bandit-report",
            str(bandit_report),
            "--pip-audit-outcome",
            "failure",
            "--bandit-outcome",
            "success",
            "--summary",
            str(summary),
        ]
    )

    assert exit_code == 0
    contents = summary.read_text(encoding="utf-8")
    assert "pip-audit dependency scan" in contents
    assert "advisory/report-only" in contents
    assert (
        "| pip-audit dependency scan | advisory/report-only | failure | 2 |" in contents
    )
    assert (
        "| Bandit Python SAST scan | advisory/report-only | success | 0 |" in contents
    )


def test_failed_advisory_scanner_without_report_fails_loudly(tmp_path):
    bandit_report = tmp_path / "bandit.json"
    summary = tmp_path / "summary.md"
    bandit_report.write_text(json.dumps({"results": []}), encoding="utf-8")

    exit_code = report_security_scanners.main(
        [
            "--pip-audit-report",
            str(tmp_path / "missing-pip-audit.json"),
            "--bandit-report",
            str(bandit_report),
            "--pip-audit-outcome",
            "failure",
            "--bandit-outcome",
            "success",
            "--summary",
            str(summary),
        ]
    )

    assert exit_code == 1
    assert "did not produce" in summary.read_text(encoding="utf-8")
