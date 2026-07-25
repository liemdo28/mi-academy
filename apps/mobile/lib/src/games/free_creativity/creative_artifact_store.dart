import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

class CreativeArtifact {
  const CreativeArtifact({
    required this.artifactId,
    required this.childProfileId,
    required this.gameId,
    required this.levelId,
    required this.sceneId,
    required this.sceneLabel,
    required this.characterId,
    required this.characterLabel,
    required this.feelingId,
    required this.feelingLabel,
    required this.storyText,
    required this.locale,
    required this.createdAt,
    required this.updatedAt,
    required this.contentVersion,
    this.storyStarterId,
    this.assetReferences = const [],
    this.revision = 1,
  });

  final String artifactId;
  final String childProfileId;
  final String gameId;
  final String levelId;
  final String sceneId;
  final String sceneLabel;
  final String characterId;
  final String characterLabel;
  final String feelingId;
  final String feelingLabel;
  final String storyText;
  final String locale;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int contentVersion;
  final String? storyStarterId;
  final List<String> assetReferences;
  final int revision;

  CreativeArtifact copyWith({
    String? storyText,
    DateTime? updatedAt,
    int? revision,
  }) {
    return CreativeArtifact(
      artifactId: artifactId,
      childProfileId: childProfileId,
      gameId: gameId,
      levelId: levelId,
      sceneId: sceneId,
      sceneLabel: sceneLabel,
      characterId: characterId,
      characterLabel: characterLabel,
      feelingId: feelingId,
      feelingLabel: feelingLabel,
      storyText: storyText ?? this.storyText,
      locale: locale,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contentVersion: contentVersion,
      storyStarterId: storyStarterId,
      assetReferences: assetReferences,
      revision: revision ?? this.revision,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'artifactId': artifactId,
      'childProfileId': childProfileId,
      'gameId': gameId,
      'levelId': levelId,
      'sceneId': sceneId,
      'sceneLabel': sceneLabel,
      'characterId': characterId,
      'characterLabel': characterLabel,
      'feelingId': feelingId,
      'feelingLabel': feelingLabel,
      'storyText': storyText,
      'locale': locale,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'contentVersion': contentVersion,
      if (storyStarterId != null) 'storyStarterId': storyStarterId,
      'assetReferences': assetReferences,
      'revision': revision,
    };
  }

  factory CreativeArtifact.fromJson(Map<String, dynamic> json) {
    return CreativeArtifact(
      artifactId: json['artifactId'].toString(),
      childProfileId: json['childProfileId'].toString(),
      gameId: json['gameId'].toString(),
      levelId: json['levelId'].toString(),
      sceneId: json['sceneId'].toString(),
      sceneLabel: json['sceneLabel'].toString(),
      characterId: json['characterId'].toString(),
      characterLabel: json['characterLabel'].toString(),
      feelingId: json['feelingId'].toString(),
      feelingLabel: json['feelingLabel'].toString(),
      storyText: json['storyText'].toString(),
      locale: json['locale'].toString(),
      createdAt: DateTime.tryParse(json['createdAt'].toString())?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: DateTime.tryParse(json['updatedAt'].toString())?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      contentVersion: json['contentVersion'] as int? ?? 1,
      storyStarterId: json['storyStarterId'] as String?,
      assetReferences: (json['assetReferences'] as List? ?? const [])
          .map((value) => value.toString())
          .toList(growable: false),
      revision: json['revision'] as int? ?? 1,
    );
  }
}

abstract class CreativeArtifactStore {
  Future<void> save(CreativeArtifact artifact);

  CreativeArtifact? load({
    required String childProfileId,
    required String artifactId,
  });

  List<CreativeArtifact> listForChild(String childProfileId);
}

class HiveCreativeArtifactStore implements CreativeArtifactStore {
  HiveCreativeArtifactStore(this._box);

  final Box _box;

  @override
  Future<void> save(CreativeArtifact artifact) async {
    await _box.put(_keyFor(artifact.childProfileId, artifact.artifactId),
        jsonEncode(artifact.toJson()));
  }

  @override
  CreativeArtifact? load({
    required String childProfileId,
    required String artifactId,
  }) {
    final raw = _box.get(_keyFor(childProfileId, artifactId));
    if (raw is! String) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final artifact = CreativeArtifact.fromJson(json);
      return artifact.childProfileId == childProfileId ? artifact : null;
    } catch (_) {
      return null;
    }
  }

  @override
  List<CreativeArtifact> listForChild(String childProfileId) {
    final artifacts = <CreativeArtifact>[];
    for (final raw in _box.values) {
      if (raw is! String) continue;
      try {
        final artifact =
            CreativeArtifact.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        if (artifact.childProfileId == childProfileId) {
          artifacts.add(artifact);
        }
      } catch (_) {}
    }
    artifacts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return artifacts;
  }

  static String _keyFor(String childProfileId, String artifactId) =>
      'creative_artifact_${childProfileId}_$artifactId';
}

class InMemoryCreativeArtifactStore implements CreativeArtifactStore {
  final Map<String, CreativeArtifact> _artifacts = {};

  @override
  Future<void> save(CreativeArtifact artifact) async {
    _artifacts[_keyFor(artifact.childProfileId, artifact.artifactId)] =
        artifact;
  }

  @override
  CreativeArtifact? load({
    required String childProfileId,
    required String artifactId,
  }) {
    return _artifacts[_keyFor(childProfileId, artifactId)];
  }

  @override
  List<CreativeArtifact> listForChild(String childProfileId) {
    final artifacts = _artifacts.values
        .where((artifact) => artifact.childProfileId == childProfileId)
        .toList();
    artifacts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return artifacts;
  }

  static String _keyFor(String childProfileId, String artifactId) =>
      '$childProfileId::$artifactId';
}
