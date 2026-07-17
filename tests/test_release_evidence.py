import subprocess
import sys
from pathlib import Path

from tools import release_evidence


def test_release_evidence_records_audio_blocker_and_pending_external_gates():
    report = release_evidence.build_report()

    assert report.status == "blocked"
    assert any(gate.gate == "Production audio audit" for gate in report.local_gates)
    audio_gate = next(
        gate for gate in report.local_gates if gate.gate == "Production audio audit"
    )
    assert audio_gate.status == "blocked"
    assert audio_gate.required_for_release is True
    assert any("Production audio audit" in blocker for blocker in report.blockers)
    assert any(
        gate.gate == "Real device/emulator smoke test"
        for gate in report.pending_external_gates
    )


def test_release_evidence_keeps_manual_signoff_pending():
    report = release_evidence.build_report()

    presignoff = next(
        gate for gate in report.local_gates if gate.gate == "Child-safety pre-signoff"
    )
    manual = next(
        gate
        for gate in report.pending_external_gates
        if gate.gate == "Manual per-game child-safety sign-off"
    )

    assert presignoff.status == "pass"
    assert "manual game reviews remain pending" in presignoff.summary
    assert manual.status == "pending"


def test_markdown_report_lists_local_and_external_evidence():
    report = release_evidence.build_report()
    markdown = release_evidence.render_markdown(report)

    assert "# MI Academy - Release Evidence Ledger" in markdown
    assert "## Local Automated Gates" in markdown
    assert "## Pending External Evidence" in markdown
    assert "Production audio audit" in markdown
    assert "Remote GitHub Actions release workflow" in markdown


def test_write_markdown_report(tmp_path):
    report = release_evidence.build_report()
    output = tmp_path / "release-evidence.md"

    release_evidence.write_markdown(report, output)

    assert output.exists()
    assert "Status:** blocked" in output.read_text(encoding="utf-8")


def test_command_gate_uses_injected_runner():
    def fake_runner(command):
        assert command == [sys.executable, "example.py"]
        return subprocess.CompletedProcess(command, 1, stdout="", stderr="boom\n")

    gate = release_evidence._command_gate(
        "Example",
        [sys.executable, "example.py"],
        fake_runner,
        pass_summary="ok",
    )

    assert gate.status == "fail"
    assert gate.summary == "boom"


def test_release_evidence_paths_are_repo_relative():
    report = release_evidence.build_report()

    for gate in report.local_gates + report.pending_external_gates:
        if gate.source.endswith(".py --json") or gate.source.endswith(".py"):
            assert not Path(gate.source.split()[0]).is_absolute()
