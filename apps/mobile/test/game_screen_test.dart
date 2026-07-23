import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/providers/providers.dart';
import 'package:mi_academy/screens/game_screen.dart';
import 'package:mi_academy/src/games/choice/choice_game_screen.dart';
import 'package:mi_academy/services/parent_settings_store.dart';
import 'package:mi_academy/services/progress_store.dart';
import 'package:mi_academy/services/reward_store.dart';
import 'package:mi_academy/services/snapshot_store.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_ui/mi_game_ui.dart';

/// Covers the production `/game/:gameId` launcher: it must render the real
/// per-game engine (loaded from the bundled level assets), not the old
/// hardcoded demo. childId is 'offline-child' throughout so the backend
/// save path (which needs network) is never exercised — see
/// api_sync_processor_test and test_api_game_result.py (backend) for that.
/// Local progress/reward recording *does* run for 'offline-child' (it's
/// network-free), so its stores are overridden too.
///
/// GameScreen reads snapshotStoreProvider/progressStoreProvider/
/// rewardStoreProvider on load or completion; override all three with
/// in-memory implementations instead of standing up real Hive boxes, which
/// need `Hive.initFlutter()` (a platform channel unavailable here).
Future<void> _pumpAndSettleLoad(
  WidgetTester tester,
  Widget child, {
  ParentSettingsSnapshot settings = const ParentSettingsSnapshot(
    language: 'vi',
    localeConfirmed: true,
  ),
  List<Override> extraOverrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        parentSettingsStoreProvider.overrideWithValue(
          MemoryParentSettingsStore(settings),
        ),
        snapshotStoreProvider.overrideWithValue(InMemorySnapshotStore()),
        progressStoreProvider.overrideWithValue(InMemoryProgressStore()),
        rewardStoreProvider.overrideWithValue(InMemoryRewardStore()),
        ...extraOverrides,
      ],
      child: MaterialApp(home: child),
    ),
  );
  // Level content loads via an async asset read, and level loading now
  // also resolves a fresh level through LevelSelector (which itself loads
  // the taxonomy/curriculum assets via activityMappingResolverProvider) --
  // more real async work than before LevelSelector existed, so give it
  // more time to complete before pumping the resulting frame.
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('renders Alphabet Explorer for gameType alphabet_explorer',
      (tester) async {
    await _pumpAndSettleLoad(
      tester,
      const GameScreen(
        childId: 'offline-child',
        gameType: 'alphabet_explorer',
      ),
    );

    expect(find.text('Tìm chữ A.'), findsOneWidget);
  });

  // Missing Letter, Word Builder, and Memory Cards GameScreen render
  // checks live in their own files -- see
  // game_screen_render_missing_letter_test.dart's doc comment for why.

  testWidgets('renders localized Missing Letter feedback in English Choice UI',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChoiceGameScreen(
          title: 'Missing Letter',
          worldLabel: 'MI looks for the missing letters with you.',
          level: _missingLetterFixture,
          allLevels: const [_missingLetterFixture],
          heroIcon: Icons.edit_note_rounded,
          primaryColor: MiGameColors.secondary,
          onExit: () {},
          onComplete: (_) {},
          locale: 'en',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Missing Letter'), findsOneWidget);
    expect(find.text('MI looks for the missing letters with you.'),
        findsOneWidget);
    expect(find.text('Choose the missing letter: C_T'), findsOneWidget);

    await tester.ensureVisible(find.text('O'));
    await tester.tap(find.text('O').first);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Almost there, try another choice.'), findsOneWidget);

    await tester.ensureVisible(find.text('A'));
    await tester.tap(find.text('A').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('You found the missing letter!'), findsOneWidget);
  });

  testWidgets('shows an error state (with retry) for an unknown game type',
      (tester) async {
    await _pumpAndSettleLoad(
      tester,
      const GameScreen(childId: 'offline-child', gameType: 'not_a_real_game'),
    );

    expect(find.text('Không thể tải trò chơi'), findsOneWidget);
  });

}

const _missingLetterFixture = MiLevel(
  id: 'ml-lv001',
  gameId: 'missing_letter',
  levelNumber: 1,
  difficulty: 1,
  localizedContent: {
    'en': {
      'prompt': 'Choose the missing letter: C_T',
      'options': [
        {'id': 'o1', 'text': 'A', 'correct': true},
        {'id': 'o2', 'text': 'O', 'correct': false},
        {'id': 'o3', 'text': 'U', 'correct': false},
      ],
    },
    'vi': {
      'prompt': 'Chọn chữ còn thiếu: M_O',
      'options': [
        {'id': 'o1', 'text': 'È', 'correct': true},
        {'id': 'o2', 'text': 'A', 'correct': false},
        {'id': 'o3', 'text': 'U', 'correct': false},
      ],
    },
  },
  hints: [
    {'text': 'Say the sounds in cat.'},
  ],
  metadata: {
    'ageGroup': 'junior',
    'skillIds': ['letters.spelling'],
  },
);
