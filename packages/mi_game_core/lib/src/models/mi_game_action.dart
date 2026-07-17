import 'package:equatable/equatable.dart';

/// An action submitted by the child during gameplay.
///
/// Games interpret actions according to their mechanic.
/// Common actions: tap, select, drag-drop, input.
class MiGameAction extends Equatable {
  const MiGameAction({
    required this.type,
    this.targetId,
    this.value,
    this.position,
    this.metadata = const {},
  });

  /// Action type identifier.
  ///
  /// Standard types:
  /// - `tap` — touch/click on an element
  /// - `select` — choose an answer option
  /// - `drag_start` — begin dragging
  /// - `drag_end` — drop an element
  /// - `input` — text/number input
  /// - `custom` — game-specific
  final String type;

  /// ID of the element acted upon.
  final String? targetId;

  /// Value of the action (answer text, number, etc.).
  final dynamic value;

  /// Screen position for spatial actions (drag-drop coordinates).
  final ({double x, double y})? position;

  /// Additional game-specific data.
  final Map<String, dynamic> metadata;

  @override
  List<Object?> get props => [type, targetId, value, position, metadata];
}
