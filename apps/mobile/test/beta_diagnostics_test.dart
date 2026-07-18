import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/services/beta_diagnostics.dart';

void main() {
  setUp(() => BetaDiagnostics.instance.clear());

  test('records a diagnostic entry with build identity on export', () {
    BetaDiagnostics.instance.record(
      category: DiagnosticCategory.network,
      summary: 'GET /api/v1/lessons timed out',
      screen: 'ChildHomeScreen',
      operation: 'loadDailyPlan',
    );

    final exported = jsonDecode(BetaDiagnostics.instance.export());

    expect(exported['app_version'], AppBuildInfo.semanticVersion);
    expect(exported['build_number'], AppBuildInfo.buildNumber);
    expect(exported['record_count'], 1);
    expect(exported['records'][0]['category'], 'network');
    expect(exported['records'][0]['screen'], 'ChildHomeScreen');
  });

  test('redacts sensitive-looking fields before they are ever stored', () {
    // Placeholder values only (not a real token/password shape) -- a more
    // realistic-looking fixture here previously tripped gitleaks' generic
    // secret-entropy heuristic in CI as a false positive.
    BetaDiagnostics.instance.record(
      category: DiagnosticCategory.authentication,
      summary: 'refresh error: {"refresh_token": "placeholder-not-a-real-token-value", "password": "placeholder-not-a-real-password"}',
    );

    final stored = BetaDiagnostics.instance.records.single.summary;

    expect(stored, isNot(contains('placeholder-not-a-real-token-value')));
    expect(stored, isNot(contains('hunter2')));
    expect(stored, contains('[REDACTED]'));
  });

  test('caps retention at 50 records, dropping the oldest first', () {
    for (var i = 0; i < 60; i++) {
      BetaDiagnostics.instance.record(
        category: DiagnosticCategory.unexpected,
        summary: 'error #$i',
      );
    }

    expect(BetaDiagnostics.instance.records.length, 50);
    expect(BetaDiagnostics.instance.records.first.summary, 'error #10');
    expect(BetaDiagnostics.instance.records.last.summary, 'error #59');
  });

  test('never includes a child name or raw token in the export shape', () {
    BetaDiagnostics.instance.record(
      category: DiagnosticCategory.database,
      summary: 'box open failed',
    );

    final exported = BetaDiagnostics.instance.export();

    expect(exported, isNot(contains('child_name')));
    expect(exported, isNot(contains('access_token')));
  });
}
