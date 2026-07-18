import 'dart:convert';

/// Static build identity for this beta -- kept as a plain constant rather
/// than pulled from a package (no `package_info_plus` dependency exists in
/// this app yet) or from real build-time git metadata (no CI step injects
/// a commit SHA via `--dart-define` yet). Keep in sync with
/// `pubspec.yaml`'s `version:` line by hand until that's automated --
/// documented here rather than silently drifting.
class AppBuildInfo {
  static const String semanticVersion = '0.9.0-beta.1';
  static const int buildNumber = 1;
  static const String releaseChannel = 'internal-beta';
}

/// Error categories a beta tester's crash/error record can be classified
/// into -- coarse enough to be useful for triage without needing the raw
/// exception text to be safe to share.
enum DiagnosticCategory {
  handledUserFacing,
  network,
  validation,
  content,
  authentication,
  synchronization,
  database,
  migration,
  unexpected,
  fatalStartup,
}

/// One redacted, safe-to-share diagnostic record.
class DiagnosticRecord {
  DiagnosticRecord({
    required this.timestamp,
    required this.category,
    required this.summary,
    this.screen,
    this.operation,
  });

  final DateTime timestamp;
  final DiagnosticCategory category;

  /// Already-redacted, human-readable summary -- never the raw
  /// exception/stack trace, which could contain request bodies, tokens,
  /// or other sensitive values depending on where the error originated.
  final String summary;
  final String? screen;
  final String? operation;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'category': category.name,
        'summary': summary,
        if (screen != null) 'screen': screen,
        if (operation != null) 'operation': operation,
      };
}

/// Fields that must never appear in a diagnostic record's summary, mirroring
/// apps/api/logging_config.py's REDACTED_KEYS list so both sides of the
/// stack agree on what's sensitive. Applied as a substring scrub over the
/// stringified error before it's ever stored -- defense in depth even
/// though callers are also expected to pass an already-safe summary.
const _sensitivePatterns = [
  'password',
  'pin',
  'access_token',
  'accessToken',
  'refresh_token',
  'refreshToken',
  'authorization',
  'secret',
];

String redact(String raw) {
  var result = raw;
  for (final pattern in _sensitivePatterns) {
    final regex = RegExp('$pattern["\']?\\s*[:=]\\s*["\']?[^"\'\\s,}]*',
        caseSensitive: false);
    result = result.replaceAll(regex, '$pattern=[REDACTED]');
  }
  return result;
}

/// Bounded, in-memory, privacy-safe beta diagnostics log.
///
/// Not a remote crash-reporting service -- no external service is
/// configured in this environment, and this class does not claim to be
/// one. It's a local structured record a developer/tester can export
/// (e.g. paste into a bug report) to give a beta issue more context than
/// "it crashed" without collecting anything sensitive.
class BetaDiagnostics {
  BetaDiagnostics._();
  static final BetaDiagnostics instance = BetaDiagnostics._();

  static const int _maxRecords = 50;
  final List<DiagnosticRecord> _records = [];

  List<DiagnosticRecord> get records => List.unmodifiable(_records);

  void record({
    required DiagnosticCategory category,
    required String summary,
    String? screen,
    String? operation,
  }) {
    _records.add(DiagnosticRecord(
      timestamp: DateTime.now().toUtc(),
      category: category,
      summary: redact(summary),
      screen: screen,
      operation: operation,
    ));
    // Bounded retention -- oldest entries drop off rather than growing
    // unbounded for the lifetime of the app session.
    while (_records.length > _maxRecords) {
      _records.removeAt(0);
    }
  }

  void clear() => _records.clear();

  /// Safe-to-share export: build identity + connectivity-adjacent counts
  /// the beta runbook's daily checks ask for, plus the redacted record
  /// list. No child name, no token, no raw exception/stack trace.
  String export() {
    final payload = {
      'app_version': AppBuildInfo.semanticVersion,
      'build_number': AppBuildInfo.buildNumber,
      'release_channel': AppBuildInfo.releaseChannel,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'record_count': _records.length,
      'records': _records.map((r) => r.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }
}
