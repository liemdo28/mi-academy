from pathlib import Path

from tools import mobile_platform_privacy_audit as audit


def test_current_mobile_platform_privacy_audit_passes():
    result = audit.audit()

    assert result.status == "pass"
    assert result.summary["fail"] == 0
    assert result.scanned_files >= 5


def test_android_sensitive_permissions_fail(tmp_path):
    manifest = tmp_path / "AndroidManifest.xml"
    manifest.write_text(
        '<manifest><uses-permission android:name="android.permission.CAMERA"/></manifest>',
        encoding="utf-8",
    )
    findings = []

    audit.scan_file(manifest, findings)

    assert findings
    assert findings[0].severity == "fail"
    assert findings[0].category == "android_permission"


def test_debug_internet_permission_warns_but_main_internet_fails(tmp_path):
    debug_manifest = tmp_path / "src" / "debug" / "AndroidManifest.xml"
    main_manifest = tmp_path / "src" / "main" / "AndroidManifest.xml"
    debug_manifest.parent.mkdir(parents=True)
    main_manifest.parent.mkdir(parents=True)
    text = '<manifest><uses-permission android:name="android.permission.INTERNET"/></manifest>'
    debug_manifest.write_text(text, encoding="utf-8")
    main_manifest.write_text(text, encoding="utf-8")
    findings = []

    audit.scan_file(debug_manifest, findings)
    audit.scan_file(main_manifest, findings)

    severities = [finding.severity for finding in findings]
    assert severities == ["warn", "fail"]


def test_ios_tracking_prompt_fails(tmp_path):
    plist = tmp_path / "Info.plist"
    plist.write_text(
        "<plist><dict><key>NSUserTrackingUsageDescription</key></dict></plist>",
        encoding="utf-8",
    )
    findings = []

    audit.scan_file(plist, findings)

    assert findings
    assert findings[0].severity == "fail"
    assert findings[0].category == "ios_privacy_key"


def test_ad_and_purchase_dependencies_fail(tmp_path):
    pubspec = tmp_path / "pubspec.yaml"
    lockfile = tmp_path / "pubspec.lock"
    pubspec.write_text("dependencies:\n  google_mobile_ads: ^1.0.0\n", encoding="utf-8")
    lockfile.write_text("packages:\n  in_app_purchase:\n", encoding="utf-8")
    findings = []

    audit.scan_file(pubspec, findings)
    audit.scan_file(lockfile, findings)

    assert [finding.category for finding in findings] == [
        "dependency",
        "dependency",
    ]


def test_platform_audit_paths_are_repo_relative():
    result = audit.audit()

    for finding in result.findings:
        assert not Path(finding.path).is_absolute()
