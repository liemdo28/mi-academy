import 'package:hive/hive.dart';
import 'package:offline_sync/offline_sync.dart';

abstract class ChildProfileStore {
  Future<List<Map<String, dynamic>>> loadProfiles();
  Future<void> saveProfiles(List<Map<String, dynamic>> profiles);
  Future<void> upsertProfile(Map<String, dynamic> profile);
  Future<Map<String, dynamic>?> loadSelectedProfile();
  Future<void> saveSelectedProfile(Map<String, dynamic> profile);
  Future<void> clearSelection();
}

class HiveChildProfileStore implements ChildProfileStore {
  HiveChildProfileStore({Box<dynamic>? box})
      : _box = box ?? Hive.box<dynamic>(MiBoxes.profiles);

  static bool get isReady => Hive.isBoxOpen(MiBoxes.profiles);

  static const _profilesKey = 'children';
  static const _selectedChildIdKey = 'selected_child_id';

  final Box<dynamic> _box;

  @override
  Future<List<Map<String, dynamic>>> loadProfiles() async {
    final raw = _box.get(_profilesKey);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where(_isUsableProfile)
        .toList(growable: false);
  }

  @override
  Future<void> saveProfiles(List<Map<String, dynamic>> profiles) async {
    await _box.put(_profilesKey, profiles.map(_normalizeProfile).toList());
  }

  @override
  Future<void> upsertProfile(Map<String, dynamic> profile) async {
    final normalized = _normalizeProfile(profile);
    final profiles = await loadProfiles();
    final index = profiles.indexWhere((item) => item['id'] == normalized['id']);
    final updated = [...profiles];
    if (index >= 0) {
      updated[index] = normalized;
    } else {
      updated.add(normalized);
    }
    await saveProfiles(updated);
  }

  @override
  Future<Map<String, dynamic>?> loadSelectedProfile() async {
    final selectedId = _box.get(_selectedChildIdKey);
    if (selectedId is! String || selectedId.isEmpty) return null;
    for (final profile in await loadProfiles()) {
      if (profile['id'] == selectedId) return profile;
    }
    return null;
  }

  @override
  Future<void> saveSelectedProfile(Map<String, dynamic> profile) async {
    final normalized = _normalizeProfile(profile);
    await upsertProfile(normalized);
    await _box.put(_selectedChildIdKey, normalized['id']);
  }

  @override
  Future<void> clearSelection() async {
    await _box.delete(_selectedChildIdKey);
  }

  static bool _isUsableProfile(Map<String, dynamic> profile) {
    return (profile['id'] as String?)?.isNotEmpty == true &&
        (profile['nickname'] as String?)?.isNotEmpty == true;
  }

  static Map<String, dynamic> _normalizeProfile(Map<String, dynamic> profile) {
    final id = profile['id'] as String;
    return {
      'id': id,
      'nickname': profile['nickname'] as String? ?? '',
      'birth_year': profile['birth_year'],
      'age_group': profile['age_group'] as String? ?? 'junior',
      'grade_level': profile['grade_level'],
      'avatar_id': profile['avatar_id'] as String? ?? 'avatar_01',
      'preferred_language': profile['preferred_language'] as String? ?? 'vi',
      'daily_time_limit': profile['daily_time_limit'],
      'created_at':
          profile['created_at'] as String? ?? DateTime.now().toIso8601String(),
      'local_only': profile['local_only'] as bool? ?? false,
    };
  }
}

class MemoryChildProfileStore implements ChildProfileStore {
  List<Map<String, dynamic>> _profiles;
  String? _selectedChildId;

  MemoryChildProfileStore({List<Map<String, dynamic>> profiles = const []})
      : _profiles = profiles.map(Map<String, dynamic>.from).toList();

  @override
  Future<List<Map<String, dynamic>>> loadProfiles() async {
    return _profiles.map(Map<String, dynamic>.from).toList();
  }

  @override
  Future<void> saveProfiles(List<Map<String, dynamic>> profiles) async {
    _profiles = profiles.map(Map<String, dynamic>.from).toList();
  }

  @override
  Future<void> upsertProfile(Map<String, dynamic> profile) async {
    final profiles = await loadProfiles();
    final index = profiles.indexWhere((item) => item['id'] == profile['id']);
    if (index >= 0) {
      profiles[index] = Map<String, dynamic>.from(profile);
    } else {
      profiles.add(Map<String, dynamic>.from(profile));
    }
    await saveProfiles(profiles);
  }

  @override
  Future<Map<String, dynamic>?> loadSelectedProfile() async {
    final selectedId = _selectedChildId;
    if (selectedId == null) return null;
    for (final profile in _profiles) {
      if (profile['id'] == selectedId) {
        return Map<String, dynamic>.from(profile);
      }
    }
    return null;
  }

  @override
  Future<void> saveSelectedProfile(Map<String, dynamic> profile) async {
    await upsertProfile(profile);
    _selectedChildId = profile['id'] as String?;
  }

  @override
  Future<void> clearSelection() async {
    _selectedChildId = null;
  }
}
