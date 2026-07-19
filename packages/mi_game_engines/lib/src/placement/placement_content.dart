import 'package:equatable/equatable.dart';

/// How a [PlacementItem]'s visual content should be rendered.
enum PlacementItemType { text, image }

/// Which fields are used to decide whether an [PlacementItem] may be
/// dropped on a given [PlacementTarget].
///
/// `explicitIds` (the default) matches [PlacementItem.acceptedTargetIds]
/// against [PlacementTarget.acceptedItemIds] directly -- this covers both
/// one-to-one placement (each item names exactly one target, each target
/// has capacity 1) and many-to-one/category sorting (several items all
/// name the same target id, that target has capacity > 1).
///
/// `metadataCategory` instead compares
/// `item.metadata[categoryMetadataKey]` to
/// `target.metadata[categoryMetadataKey]` -- useful when authoring many
/// items against few targets without repeating target ids on every item
/// (e.g. "every item whose metadata.category == 'animal' belongs on the
/// Animals target").
enum PlacementMatchStrategy { explicitIds, metadataCategory }

/// Governs which items may be dropped on which targets for one
/// [PlacementContent] level.
class PlacementRule extends Equatable {
  const PlacementRule({
    this.matchStrategy = PlacementMatchStrategy.explicitIds,
    this.categoryMetadataKey,
  });

  factory PlacementRule.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PlacementRule();
    final strategyRaw = json['matchStrategy'] as String?;
    final strategy = strategyRaw == 'metadataCategory'
        ? PlacementMatchStrategy.metadataCategory
        : PlacementMatchStrategy.explicitIds;
    final categoryKey = json['categoryMetadataKey'] as String?;
    if (strategy == PlacementMatchStrategy.metadataCategory &&
        (categoryKey == null || categoryKey.isEmpty)) {
      throw PlacementContentException(
        'rule.categoryMetadataKey is required when matchStrategy is '
        '"metadataCategory"',
      );
    }
    return PlacementRule(
      matchStrategy: strategy,
      categoryMetadataKey: categoryKey,
    );
  }

  final PlacementMatchStrategy matchStrategy;
  final String? categoryMetadataKey;

  /// Whether [item] is allowed to be dropped on [target] under this rule.
  bool accepts(PlacementItem item, PlacementTarget target) {
    if (matchStrategy == PlacementMatchStrategy.metadataCategory) {
      final key = categoryMetadataKey!;
      return item.metadata[key] != null &&
          item.metadata[key] == target.metadata[key];
    }
    final itemAllows = item.acceptedTargetIds.isEmpty ||
        item.acceptedTargetIds.contains(target.id);
    final targetAllows = target.acceptedItemIds.isEmpty ||
        target.acceptedItemIds.contains(item.id);
    return itemAllows && targetAllows;
  }

  /// Whether [item] and [target] each explicitly name the other but the
  /// other's own explicit list excludes them -- a contradictory pair of
  /// authoring rules distinct from "no valid target at all".
  bool isContradictory(PlacementItem item, PlacementTarget target) {
    if (matchStrategy == PlacementMatchStrategy.metadataCategory) return false;
    final itemNamesTarget = item.acceptedTargetIds.contains(target.id);
    final targetExcludesItem = target.acceptedItemIds.isNotEmpty &&
        !target.acceptedItemIds.contains(item.id);
    final targetNamesItem = target.acceptedItemIds.contains(item.id);
    final itemExcludesTarget = item.acceptedTargetIds.isNotEmpty &&
        !item.acceptedTargetIds.contains(target.id);
    return (itemNamesTarget && targetExcludesItem) ||
        (targetNamesItem && itemExcludesTarget);
  }

  @override
  List<Object?> get props => [matchStrategy, categoryMetadataKey];
}

/// Global gameplay configuration for one [PlacementContent] level.
class PlacementConfiguration extends Equatable {
  const PlacementConfiguration({
    this.snapToTarget = true,
    this.returnToOriginOnInvalidDrop = true,
    this.allowMoveBetweenTargets = true,
    this.allowRemoveFromTarget = true,
    this.shuffleItems = true,
    this.allowedRotations = const {0},
    this.tapAccessibilityMode = false,
    this.requireAllItemsPlacedForCompletion = true,
  });

  factory PlacementConfiguration.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PlacementConfiguration();
    final rawRotations = json['allowedRotations'] as List?;
    final rotations = rawRotations == null
        ? const {0}
        : rawRotations.map((e) => e as int).toSet();
    return PlacementConfiguration(
      snapToTarget: json['snapToTarget'] as bool? ?? true,
      returnToOriginOnInvalidDrop:
          json['returnToOriginOnInvalidDrop'] as bool? ?? true,
      allowMoveBetweenTargets: json['allowMoveBetweenTargets'] as bool? ?? true,
      allowRemoveFromTarget: json['allowRemoveFromTarget'] as bool? ?? true,
      shuffleItems: json['shuffleItems'] as bool? ?? true,
      allowedRotations: rotations,
      tapAccessibilityMode: json['tapAccessibilityMode'] as bool? ?? false,
      requireAllItemsPlacedForCompletion:
          json['requireAllItemsPlacedForCompletion'] as bool? ?? true,
    );
  }

  final bool snapToTarget;
  final bool returnToOriginOnInvalidDrop;
  final bool allowMoveBetweenTargets;
  final bool allowRemoveFromTarget;
  final bool shuffleItems;
  final Set<int> allowedRotations;
  final bool tapAccessibilityMode;
  final bool requireAllItemsPlacedForCompletion;

  @override
  List<Object?> get props => [
        snapToTarget,
        returnToOriginOnInvalidDrop,
        allowMoveBetweenTargets,
        allowRemoveFromTarget,
        shuffleItems,
        allowedRotations,
        tapAccessibilityMode,
        requireAllItemsPlacedForCompletion,
      ];
}

/// Optional absolute layout hint for a [PlacementTarget]. Both fields must
/// be finite, non-negative numbers when present -- this is layout
/// metadata for hosts that want a fixed spatial arrangement (e.g. a map),
/// not a requirement for [PlacementScreen]'s default flow layout.
class PlacementPosition extends Equatable {
  const PlacementPosition({required this.x, required this.y});

  factory PlacementPosition.fromJson(Map<String, dynamic> json) {
    final x = json['x'];
    final y = json['y'];
    if (x is! num || y is! num || x < 0 || y < 0) {
      throw PlacementContentException(
        'position must have non-negative numeric x/y, got x=$x y=$y',
      );
    }
    return PlacementPosition(x: x.toDouble(), y: y.toDouble());
  }

  final double x;
  final double y;

  @override
  List<Object?> get props => [x, y];
}

/// Optional layout size hint for a [PlacementTarget]. See
/// [PlacementPosition] for the same validation rationale.
class PlacementSize extends Equatable {
  const PlacementSize({required this.width, required this.height});

  factory PlacementSize.fromJson(Map<String, dynamic> json) {
    final width = json['width'];
    final height = json['height'];
    if (width is! num || height is! num || width <= 0 || height <= 0) {
      throw PlacementContentException(
        'size must have positive numeric width/height, got '
        'width=$width height=$height',
      );
    }
    return PlacementSize(width: width.toDouble(), height: height.toDouble());
  }

  final double width;
  final double height;

  @override
  List<Object?> get props => [width, height];
}

/// One draggable/selectable piece to be placed on a [PlacementTarget].
class PlacementItem extends Equatable {
  const PlacementItem({
    required this.id,
    required this.label,
    this.text,
    this.assetId,
    this.type = PlacementItemType.text,
    this.acceptedTargetIds = const [],
    this.initialOrder = 0,
    this.rotationDegrees,
    this.metadata = const {},
  });

  factory PlacementItem.fromJson(Map<String, dynamic> json) {
    for (final field in ['id', 'label']) {
      if (!json.containsKey(field) ||
          (json[field] as String?)?.isEmpty == true) {
        throw PlacementContentException(
            'Item is missing required field "$field"');
      }
    }
    final rawTargetIds = json['acceptedTargetIds'] as List? ?? const [];
    return PlacementItem(
      id: json['id'] as String,
      label: json['label'] as String,
      text: json['text'] as String?,
      assetId: json['assetId'] as String?,
      type: json['type'] == 'image'
          ? PlacementItemType.image
          : PlacementItemType.text,
      acceptedTargetIds: rawTargetIds.cast<String>(),
      initialOrder: json['initialOrder'] as int? ?? 0,
      rotationDegrees: json['rotationDegrees'] as int?,
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  final String id;
  final String label;
  final String? text;
  final String? assetId;
  final PlacementItemType type;
  final List<String> acceptedTargetIds;
  final int initialOrder;
  final int? rotationDegrees;
  final Map<String, dynamic> metadata;

  @override
  List<Object?> get props => [
        id,
        label,
        text,
        assetId,
        type,
        acceptedTargetIds,
        initialOrder,
        rotationDegrees,
        metadata,
      ];
}

/// One drop zone that accepts up to [capacity] [PlacementItem]s.
class PlacementTarget extends Equatable {
  const PlacementTarget({
    required this.id,
    required this.label,
    this.text,
    this.assetId,
    this.capacity = 1,
    this.acceptedItemIds = const [],
    this.position,
    this.size,
    this.completionGroup,
    this.metadata = const {},
  });

  factory PlacementTarget.fromJson(Map<String, dynamic> json) {
    for (final field in ['id', 'label']) {
      if (!json.containsKey(field) ||
          (json[field] as String?)?.isEmpty == true) {
        throw PlacementContentException(
            'Target is missing required field "$field"');
      }
    }
    final capacity = json['capacity'] as int? ?? 1;
    if (capacity <= 0) {
      throw PlacementContentException(
        'Target "${json['id']}" has non-positive capacity: $capacity',
      );
    }
    final rawItemIds = json['acceptedItemIds'] as List? ?? const [];
    final rawPosition = json['position'] as Map<String, dynamic>?;
    final rawSize = json['size'] as Map<String, dynamic>?;
    return PlacementTarget(
      id: json['id'] as String,
      label: json['label'] as String,
      text: json['text'] as String?,
      assetId: json['assetId'] as String?,
      capacity: capacity,
      acceptedItemIds: rawItemIds.cast<String>(),
      position:
          rawPosition == null ? null : PlacementPosition.fromJson(rawPosition),
      size: rawSize == null ? null : PlacementSize.fromJson(rawSize),
      completionGroup: json['completionGroup'] as String?,
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  final String id;
  final String label;
  final String? text;
  final String? assetId;
  final int capacity;
  final List<String> acceptedItemIds;
  final PlacementPosition? position;
  final PlacementSize? size;
  final String? completionGroup;
  final Map<String, dynamic> metadata;

  @override
  List<Object?> get props => [
        id,
        label,
        text,
        assetId,
        capacity,
        acceptedItemIds,
        position,
        size,
        completionGroup,
        metadata,
      ];
}

/// Typed content for one Drag-and-drop Placement Engine level -- see
/// docs/game-engine-architecture.md. Independent of `MiLevel`
/// (packages/mi_game_core), same rationale as MatchingContent/
/// SequenceContent: this engine's content has real internal structure
/// (typed items/targets/rules), not an opaque `Map<String, dynamic>`.
class PlacementContent extends Equatable {
  const PlacementContent({
    required this.contentId,
    required this.gameId,
    required this.locale,
    required this.ageBand,
    required this.difficulty,
    required this.instruction,
    required this.items,
    required this.targets,
    this.hint,
    this.rule = const PlacementRule(),
    this.configuration = const PlacementConfiguration(),
    this.estimatedSeconds = 60,
    this.schemaVersion = '1.0',
  });

  static const supportedSchemaVersions = {'1.0'};

  final String contentId;
  final String gameId;
  final String locale;
  final String ageBand;
  final int difficulty;
  final String instruction;
  final String? hint;
  final List<PlacementItem> items;
  final List<PlacementTarget> targets;
  final PlacementRule rule;
  final PlacementConfiguration configuration;
  final int estimatedSeconds;
  final String schemaVersion;

  /// Every target id [item] may legally be dropped on, per [rule].
  List<String> acceptableTargetIdsFor(PlacementItem item) => [
        for (final target in targets)
          if (rule.accepts(item, target)) target.id,
      ];

  /// Every item id [target] may legally receive, per [rule].
  List<String> acceptableItemIdsFor(PlacementTarget target) => [
        for (final item in items)
          if (rule.accepts(item, target)) item.id,
      ];

  /// Parses and validates [json], throwing [PlacementContentException]
  /// with an actionable message (content id, field, item/target id where
  /// relevant, and the reason) for any malformed or logically-impossible
  /// content, rather than a bare cast failure or a later assertion.
  factory PlacementContent.fromJson(Map<String, dynamic> json) {
    final contentId = json['contentId'] as String? ?? '(unknown)';
    void fail(String message) =>
        throw PlacementContentException('[$contentId] $message');

    final missing = <String>[
      for (final field in [
        'contentId',
        'gameId',
        'locale',
        'ageBand',
        'difficulty',
        'instruction',
        'items',
        'targets',
      ])
        if (!json.containsKey(field)) field,
    ];
    if (missing.isNotEmpty) fail('Missing required field(s): $missing');

    final schemaVersion = json['schemaVersion'] as String? ?? '1.0';
    if (!supportedSchemaVersions.contains(schemaVersion)) {
      fail('Unsupported schemaVersion: $schemaVersion');
    }

    final difficulty = json['difficulty'];
    if (difficulty is! int || difficulty < 1 || difficulty > 5) {
      fail('difficulty must be an integer 1-5, got $difficulty');
    }

    final configuration = PlacementConfiguration.fromJson(
        json['configuration'] as Map<String, dynamic>?);
    final PlacementRule rule;
    try {
      rule = PlacementRule.fromJson(json['rule'] as Map<String, dynamic>?);
    } on PlacementContentException catch (e) {
      fail(e.message);
      rethrow; // unreachable, keeps analyzer happy about definite assignment
    }

    final rawItems = json['items'] as List?;
    if (rawItems == null || rawItems.isEmpty) {
      fail('items must be a non-empty list');
    }
    final rawTargets = json['targets'] as List?;
    if (rawTargets == null || rawTargets.isEmpty) {
      fail('targets must be a non-empty list');
    }

    final items = <PlacementItem>[];
    final seenItemIds = <String>{};
    for (final raw in rawItems!) {
      final PlacementItem item;
      try {
        item = PlacementItem.fromJson(raw as Map<String, dynamic>);
      } on PlacementContentException catch (e) {
        fail(e.message);
        rethrow;
      }
      if (!seenItemIds.add(item.id)) {
        fail('Duplicate item id: ${item.id}');
      }
      if (item.rotationDegrees != null &&
          !configuration.allowedRotations.contains(item.rotationDegrees)) {
        fail(
          'Item "${item.id}" has unsupported rotationDegrees '
          '${item.rotationDegrees} (allowed: ${configuration.allowedRotations})',
        );
      }
      items.add(item);
    }

    final targets = <PlacementTarget>[];
    final seenTargetIds = <String>{};
    for (final raw in rawTargets!) {
      final PlacementTarget target;
      try {
        target = PlacementTarget.fromJson(raw as Map<String, dynamic>);
      } on PlacementContentException catch (e) {
        fail(e.message);
        rethrow;
      }
      if (!seenTargetIds.add(target.id)) {
        fail('Duplicate target id: ${target.id}');
      }
      targets.add(target);
    }

    // Cross-reference: item -> target and target -> item existence.
    for (final item in items) {
      for (final targetId in item.acceptedTargetIds) {
        if (!seenTargetIds.contains(targetId)) {
          fail('Item "${item.id}" references unknown target "$targetId"');
        }
      }
    }
    for (final target in targets) {
      for (final itemId in target.acceptedItemIds) {
        if (!seenItemIds.contains(itemId)) {
          fail('Target "${target.id}" references unknown item "$itemId"');
        }
      }
    }

    // Contradictory explicit rules (item and target each explicitly
    // disagree about the other), distinct from "no valid target at all".
    for (final item in items) {
      for (final target in targets) {
        if (rule.isContradictory(item, target)) {
          fail(
            'Contradictory placement rule between item "${item.id}" and '
            'target "${target.id}"',
          );
        }
      }
    }

    // Every item must have at least one legal target.
    for (final item in items) {
      final acceptableTargets = [
        for (final target in targets)
          if (rule.accepts(item, target)) target,
      ];
      if (acceptableTargets.isEmpty) {
        fail('Item "${item.id}" has no valid target');
      }
    }

    // Every target must be reachable by at least one item (an
    // unreachable target is dead content, not a warning).
    for (final target in targets) {
      final hasReachingItem = items.any((item) => rule.accepts(item, target));
      if (!hasReachingItem) {
        fail('Target "${target.id}" has no valid item');
      }
    }

    // Total demand must not exceed total supply.
    final totalCapacity = targets.fold<int>(0, (sum, t) => sum + t.capacity);
    if (items.length > totalCapacity) {
      fail(
        'Total items (${items.length}) exceed total target capacity '
        '($totalCapacity)',
      );
    }

    // Impossible completion: items that can ONLY go on one target,
    // stacked up past that target's capacity.
    final exclusiveDemand = <String, int>{};
    for (final item in items) {
      final acceptable = [
        for (final target in targets)
          if (rule.accepts(item, target)) target.id,
      ];
      if (acceptable.length == 1) {
        exclusiveDemand[acceptable.single] =
            (exclusiveDemand[acceptable.single] ?? 0) + 1;
      }
    }
    for (final target in targets) {
      final demand = exclusiveDemand[target.id] ?? 0;
      if (demand > target.capacity) {
        fail(
          'Impossible completion: $demand item(s) require target '
          '"${target.id}" exclusively but its capacity is ${target.capacity}',
        );
      }
    }

    return PlacementContent(
      contentId: json['contentId'] as String,
      gameId: json['gameId'] as String,
      locale: json['locale'] as String,
      ageBand: json['ageBand'] as String,
      difficulty: difficulty as int,
      instruction: json['instruction'] as String,
      hint: json['hint'] as String?,
      items: items,
      targets: targets,
      rule: rule,
      configuration: configuration,
      estimatedSeconds: json['estimatedSeconds'] as int? ?? 60,
      schemaVersion: schemaVersion,
    );
  }

  @override
  List<Object?> get props => [
        contentId,
        gameId,
        locale,
        ageBand,
        difficulty,
        instruction,
        hint,
        items,
        targets,
        rule,
        configuration,
        estimatedSeconds,
        schemaVersion,
      ];
}

class PlacementContentException implements Exception {
  PlacementContentException(this.message);
  final String message;

  @override
  String toString() => 'PlacementContentException: $message';
}
