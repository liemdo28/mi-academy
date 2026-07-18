import 'dart:convert' as convert;

import 'package:hive_flutter/hive_flutter.dart';

class ParentSettingsSnapshot {
  const ParentSettingsSnapshot({
    this.dailyLimitMinutes = 30,
    this.soundEnabled = true,
    this.subtitlesEnabled = false,
    this.reduceMotion = false,
    this.language = 'vi',
    this.offlineReady = false,
    this.exportPreparedAt,
    this.deleteRequestedAt,
  });

  final int dailyLimitMinutes;
  final bool soundEnabled;
  final bool subtitlesEnabled;
  /// Skips/shortens game animations (e.g. Memory Cards' flip transition)
  /// for children sensitive to motion. Threaded down to games via
  /// MiGameContext.accessibility -- see memory_cards_screen.dart.
  final bool reduceMotion;
  final String language;
  final bool offlineReady;
  final DateTime? exportPreparedAt;
  final DateTime? deleteRequestedAt;

  bool get exportReady => exportPreparedAt != null;
  bool get deleteConfirmed => deleteRequestedAt != null;

  ParentSettingsSnapshot copyWith({
    int? dailyLimitMinutes,
    bool? soundEnabled,
    bool? subtitlesEnabled,
    bool? reduceMotion,
    String? language,
    bool? offlineReady,
    DateTime? exportPreparedAt,
    DateTime? deleteRequestedAt,
    bool clearExportPreparedAt = false,
    bool clearDeleteRequestedAt = false,
  }) {
    return ParentSettingsSnapshot(
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      subtitlesEnabled: subtitlesEnabled ?? this.subtitlesEnabled,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      language: language ?? this.language,
      offlineReady: offlineReady ?? this.offlineReady,
      exportPreparedAt: clearExportPreparedAt
          ? null
          : exportPreparedAt ?? this.exportPreparedAt,
      deleteRequestedAt: clearDeleteRequestedAt
          ? null
          : deleteRequestedAt ?? this.deleteRequestedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'dailyLimitMinutes': dailyLimitMinutes,
      'soundEnabled': soundEnabled,
      'subtitlesEnabled': subtitlesEnabled,
      'reduceMotion': reduceMotion,
      'language': language,
      'offlineReady': offlineReady,
      'exportPreparedAt': exportPreparedAt?.toIso8601String(),
      'deleteRequestedAt': deleteRequestedAt?.toIso8601String(),
    };
  }

  Map<String, Object?> toParentExportJson() {
    return {
      'schema': 'mi-academy-parent-settings-export-v1',
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'childProfile': {
        'id': 'offline-child',
        'ageGroup': 'MI Junior',
        'language': language,
      },
      'settings': {
        'dailyLimitMinutes': dailyLimitMinutes,
        'soundEnabled': soundEnabled,
        'subtitlesEnabled': subtitlesEnabled,
        'offlineReady': offlineReady,
      },
      'privacy': {
        'containsPersonalContactInfo': false,
        'containsLocationData': false,
        'deleteRequestedAt': deleteRequestedAt?.toIso8601String(),
      },
    };
  }

  static ParentSettingsSnapshot fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) return const ParentSettingsSnapshot();
    return ParentSettingsSnapshot(
      dailyLimitMinutes: _intValue(json['dailyLimitMinutes'], fallback: 30),
      soundEnabled: _boolValue(json['soundEnabled'], fallback: true),
      subtitlesEnabled: _boolValue(json['subtitlesEnabled']),
      reduceMotion: _boolValue(json['reduceMotion']),
      language: json['language'] == 'en' ? 'en' : 'vi',
      offlineReady: _boolValue(json['offlineReady']),
      exportPreparedAt: _dateValue(json['exportPreparedAt']),
      deleteRequestedAt: _dateValue(json['deleteRequestedAt']),
    );
  }

  static int _intValue(Object? value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.round();
    return fallback;
  }

  static bool _boolValue(Object? value, {bool fallback = false}) {
    if (value is bool) return value;
    return fallback;
  }

  static DateTime? _dateValue(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

abstract class ParentSettingsStore {
  Future<ParentSettingsSnapshot> load();
  Future<void> save(ParentSettingsSnapshot snapshot);
  Future<String> prepareExport(ParentSettingsSnapshot snapshot);
  Future<void> deleteChildData();
}

class MemoryParentSettingsStore implements ParentSettingsStore {
  MemoryParentSettingsStore([ParentSettingsSnapshot? initial])
      : _snapshot = initial ?? const ParentSettingsSnapshot();

  ParentSettingsSnapshot _snapshot;
  String? lastExportJson;

  @override
  Future<ParentSettingsSnapshot> load() async => _snapshot;

  @override
  Future<void> save(ParentSettingsSnapshot snapshot) async {
    _snapshot = snapshot;
  }

  @override
  Future<String> prepareExport(ParentSettingsSnapshot snapshot) async {
    lastExportJson = const convert.JsonEncoder.withIndent('  ')
        .convert(snapshot.toParentExportJson());
    return lastExportJson!;
  }

  @override
  Future<void> deleteChildData() async {
    _snapshot = const ParentSettingsSnapshot(
      dailyLimitMinutes: 30,
      language: 'vi',
      offlineReady: false,
      deleteRequestedAt: null,
    );
  }
}

class HiveParentSettingsStore implements ParentSettingsStore {
  HiveParentSettingsStore(this._box);

  static const boxName = 'parent_settings';
  static const _snapshotKey = 'snapshot';
  static const _exportKey = 'latest_export_json';

  final Box<dynamic> _box;

  static Future<HiveParentSettingsStore> open() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<dynamic>(boxName);
    return HiveParentSettingsStore(box);
  }

  @override
  Future<ParentSettingsSnapshot> load() async {
    final raw = _box.get(_snapshotKey);
    if (raw is Map) return ParentSettingsSnapshot.fromJson(raw);
    return const ParentSettingsSnapshot();
  }

  @override
  Future<void> save(ParentSettingsSnapshot snapshot) async {
    await _box.put(_snapshotKey, snapshot.toJson());
  }

  @override
  Future<String> prepareExport(ParentSettingsSnapshot snapshot) async {
    final json = const convert.JsonEncoder.withIndent('  ')
        .convert(snapshot.toParentExportJson());
    await _box.put(_exportKey, json);
    return json;
  }

  @override
  Future<void> deleteChildData() async {
    await _box.delete(_snapshotKey);
    await _box.delete(_exportKey);
  }
}
