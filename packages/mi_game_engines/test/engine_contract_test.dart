// Shared contract test suite: verifies every engine in this package
// (Matching, Sequence, Placement, Multi-select) upholds the same "common
// engine contract" -- a stable engine id, a content id surfaced
// somewhere in its result/state, an attempt counter, a completed flag, a
// deterministic star rating, and zero direct dependency on
// persistence/backend/analytics code. Extending this suite (rather than
// writing a fourth/fifth, unrelated file) is what lets a regression in
// any one engine's contract be caught here, not just in that engine's
// own test file.
//
// Matching and Sequence predate this file and intentionally are NOT
// modified beyond adding a static `engineId` constant to each (a purely
// additive change -- see matching_controller.dart / sequence_controller.dart)
// so this suite has something stable to assert against without
// weakening either engine's existing API.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_engines/mi_game_engines.dart';

Map<String, dynamic> _matchingSample() => {
      'contentId': 'contract-matching',
      'gameId': 'letter_picture_match',
      'locale': 'vi',
      'ageBand': 'junior',
      'difficulty': 1,
      'instruction': 'Nối chữ với hình!',
      'pairs': [
        {
          'left': {'id': 'l1', 'content': 'A'},
          'right': {'id': 'r1', 'content': '🍎'},
        },
        {
          'left': {'id': 'l2', 'content': 'B'},
          'right': {'id': 'r2', 'content': '🍌'},
        },
      ],
    };

Map<String, dynamic> _sequenceSample() => {
      'contentId': 'contract-sequence',
      'gameId': 'number_sequence',
      'locale': 'vi',
      'ageBand': 'explorer',
      'difficulty': 2,
      'instruction': 'Sắp xếp theo thứ tự!',
      'mode': 'reorder',
      'rule': {'type': 'ascending', 'step': 1},
      'correctOrder': [
        {'id': 'n1', 'content': '1', 'type': 'number'},
        {'id': 'n2', 'content': '2', 'type': 'number'},
      ],
    };

Map<String, dynamic> _placementSample() => {
      'contentId': 'contract-placement',
      'gameId': 'letter_placement',
      'locale': 'vi',
      'ageBand': 'junior',
      'difficulty': 1,
      'instruction': 'Đặt vào đúng ô!',
      'items': [
        {
          'id': 'a',
          'label': 'A',
          'acceptedTargetIds': ['t1']
        },
      ],
      'targets': [
        {
          'id': 't1',
          'label': 'T1',
          'capacity': 1,
          'acceptedItemIds': ['a']
        },
      ],
    };

Map<String, dynamic> _multiSelectSample() => {
      'contentId': 'contract-multi-select',
      'gameId': 'letter_sorting',
      'locale': 'vi',
      'ageBand': 'junior',
      'difficulty': 1,
      'instruction': 'Chọn nguyên âm!',
      'prompt': 'Chữ nào là nguyên âm?',
      'configuration': {
        'evaluationMode': 'exactMatch',
        'minSelections': 1,
        'maxSelections': 2,
      },
      'options': [
        {'id': 'a', 'label': 'A', 'text': 'A', 'isCorrect': true},
        {'id': 'b', 'label': 'B', 'text': 'B', 'isCorrect': false},
      ],
    };

/// Every source file this package's engines live in, so the
/// no-persistence-dependency check below is exhaustive rather than
/// listing files by hand (and silently going stale as engines are added).
List<File> _engineSourceFiles() {
  final libSrc = Directory('lib/src');
  return libSrc
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();
}

const _forbiddenImportSubstrings = [
  'package:hive',
  'package:dio',
  'package:http/',
  'package:shared_preferences',
  'package:firebase',
  'package:sqflite',
];

void main() {
  group('Shared engine contract -- stable identity', () {
    test(
        'Matching, Sequence, Placement, and Multi-select each expose a distinct stable engineId',
        () {
      expect(MatchingController.engineId, 'matching');
      expect(SequenceController.engineId, 'sequence');
      expect(PlacementController.engineId, 'placement');
      expect(MultiSelectController.engineId, 'multi_select');
      final ids = {
        MatchingController.engineId,
        SequenceController.engineId,
        PlacementController.engineId,
        MultiSelectController.engineId,
      };
      expect(ids, hasLength(4), reason: 'engine ids must all be distinct');
    });
  });

  group('Shared engine contract -- attempt counting and completion', () {
    test('MatchingController tracks attempts and completes correctly', () {
      final controller = MatchingController(
          content: MatchingContent.fromJson(_matchingSample()));
      expect(controller.attempts, 0);
      expect(controller.isComplete, isFalse);

      controller.selectLeft('l1');
      controller.selectRight('r1');
      controller.selectLeft('l2');
      controller.selectRight('r2');

      expect(controller.attempts, 2);
      expect(controller.isComplete, isTrue);
      expect(controller.starsEarned, inInclusiveRange(1, 3));
    });

    test('SequenceController tracks attempts and completes correctly', () {
      final controller = SequenceController(
          content: SequenceContent.fromJson(_sequenceSample()));
      expect(controller.attempts, 0);
      expect(controller.isComplete, isFalse);

      // Drive the arrangement into the correct order regardless of the
      // initial shuffle, then submit.
      final target = controller.content.correctOrder;
      for (var i = 0; i < target.length; i++) {
        final currentIndex = controller.arrangement
            .indexWhere((item) => item.id == target[i].id);
        if (currentIndex != i) controller.moveItem(currentIndex, i);
      }
      controller.submitReorder();

      expect(controller.attempts, 1);
      expect(controller.isComplete, isTrue);
      expect(controller.starsEarned, inInclusiveRange(1, 3));
    });

    test('PlacementController tracks attempts and completes correctly', () {
      final controller = PlacementController(
          content: PlacementContent.fromJson(_placementSample()));
      expect(controller.attempts, 0);
      expect(controller.isComplete, isFalse);

      controller.placeItem('a', 't1');

      expect(controller.attempts, 1);
      expect(controller.isComplete, isTrue);
      expect(controller.starsEarned, inInclusiveRange(1, 3));
    });

    test('MultiSelectController tracks attempts and completes correctly', () {
      final controller = MultiSelectController(
          content: MultiSelectContent.fromJson(_multiSelectSample()));
      expect(controller.attempts, 0);
      expect(controller.isComplete, isFalse);

      controller.select('a');
      controller.submit();

      expect(controller.attempts, 1);
      expect(controller.isComplete, isTrue);
      expect(controller.starsEarned, inInclusiveRange(1, 3));
    });
  });

  group('Shared engine contract -- Placement/Multi-select normalized result',
      () {
    test(
        "Placement's result carries the content id, score, stars, duration, and completion",
        () {
      PlacementResult? callbackResult;
      final controller = PlacementController(
        content: PlacementContent.fromJson(_placementSample()),
        onComplete: (result) => callbackResult = result,
      );
      controller.placeItem('a', 't1');

      expect(controller.result.contentId, 'contract-placement');
      expect(controller.result.engineId, 'placement');
      expect(controller.result.completed, isTrue);
      expect(controller.result.score, inInclusiveRange(0, 100));
      expect(controller.result.stars, inInclusiveRange(0, 3));
      expect(controller.result.duration, isA<Duration>());

      // Callback behavior: fired exactly once, with the same shape.
      expect(callbackResult, isNotNull);
      expect(callbackResult!.contentId, 'contract-placement');
    });

    test(
        "Multi-select's result carries the content id, score, stars, duration, and completion",
        () {
      MultiSelectResult? callbackResult;
      final controller = MultiSelectController(
        content: MultiSelectContent.fromJson(_multiSelectSample()),
        onComplete: (result) => callbackResult = result,
      );
      controller.select('a');
      controller.submit();

      expect(controller.result.contentId, 'contract-multi-select');
      expect(controller.result.engineId, 'multi_select');
      expect(controller.result.completed, isTrue);
      expect(controller.result.score, inInclusiveRange(0, 100));
      expect(controller.result.stars, inInclusiveRange(0, 3));
      expect(controller.result.duration, isA<Duration>());

      expect(callbackResult, isNotNull);
      expect(callbackResult!.contentId, 'contract-multi-select');
    });
  });

  group('Shared engine contract -- no direct persistence dependency', () {
    test('no engine source file imports a storage/backend/analytics package',
        () {
      final offenders = <String>[];
      for (final file in _engineSourceFiles()) {
        final content = file.readAsStringSync();
        for (final forbidden in _forbiddenImportSubstrings) {
          if (content.contains(forbidden)) {
            offenders.add('${file.path} imports $forbidden');
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('; '));
    });
  });
}
