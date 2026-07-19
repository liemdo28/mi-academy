import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mi_academy/providers/auth_provider.dart';
import 'package:mi_academy/providers/child_provider.dart';
import 'package:mi_academy/providers/providers.dart';
import 'package:mi_academy/services/api_service.dart';
import 'package:offline_sync/offline_sync.dart';

import 'helpers/app_launch.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await resetLocalState();
  });

  testWidgets('Category Collector completes and queues offline progress', (
    tester,
  ) async {
    await _launchGame(
      tester,
      gameId: 'category_collector',
      title: 'Nhom do vat',
      subject: 'logic',
    );

    expect(find.text('Chon tat ca con vat.'), findsWidgets);
    await _tapAll(tester, ['meo', 'cho', 'chim']);
    await _tapCheckAnswers(tester);

    _expectQueuedResult('category_collector', 'cc-lv001');
  });

  testWidgets('Pattern Parade completes and queues offline progress', (
    tester,
  ) async {
    await _launchGame(
      tester,
      gameId: 'pattern_parade',
      title: 'Dieu hanh mau hinh',
      subject: 'logic',
    );

    final answer = find.text('blue').last;
    await tester.ensureVisible(answer);
    await tester.tap(answer);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Kiểm tra'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    _expectQueuedResult('pattern_parade', 'pp-lv001');
  });

  testWidgets('Shape Builder completes and queues offline progress', (
    tester,
  ) async {
    await _launchGame(
      tester,
      gameId: 'shape_builder',
      title: 'Lap ghep hinh',
      subject: 'math',
    );

    expect(find.text('Sap xep vao hinh tron hoac hinh co goc.'), findsWidgets);
    await _placeAll(tester, {
      'circle': 'circle shapes',
      'oval': 'circle shapes',
      'wheel': 'circle shapes',
      'square': 'corner shapes',
      'triangle': 'corner shapes',
      'block': 'corner shapes',
    });

    _expectQueuedResult('shape_builder', 'sb-lv001');
  });

  testWidgets('Word Sorter completes and queues offline progress', (
    tester,
  ) async {
    await _launchGame(
      tester,
      gameId: 'word_sorter',
      title: 'Sap xep tu',
      subject: 'letters',
    );

    expect(find.text('Sap xep vao danh tu hoac dong tu.'), findsWidgets);
    await _placeAll(tester, {
      'book': 'noun',
      'tree': 'noun',
      'cup': 'noun',
      'jump': 'verb',
      'run': 'verb',
      'read': 'verb',
    });

    _expectQueuedResult('word_sorter', 'ws-lv001');
  });

  testWidgets('Number Balance completes and queues offline progress', (
    tester,
  ) async {
    await _launchGame(
      tester,
      gameId: 'number_balance',
      title: 'Can bang so',
      subject: 'math',
    );

    expect(
      find.text('Ghep moi phep tinh voi gia tri bang nhau.'),
      findsWidgets,
    );
    await _matchAll(tester, {
      '3 + 1': '4',
      '4 + 1': '5',
      '5 + 1': '6',
      '6 + 1': '7',
    });

    _expectQueuedResult('number_balance', 'nb-lv001');
  });

  testWidgets('Logic Detective completes and queues offline progress', (
    tester,
  ) async {
    await _launchGame(
      tester,
      gameId: 'logic_detective',
      title: 'Tham tu logic',
      subject: 'logic',
    );

    expect(find.text('Chon moi so chia het cho 3.'), findsWidgets);
    await _tapAll(tester, ['3', '6']);
    await _tapCheckAnswers(tester);

    _expectQueuedResult('logic_detective', 'ld-lv001');
  });

  testWidgets('Story Steps completes and queues offline progress', (
    tester,
  ) async {
    await _launchGame(
      tester,
      gameId: 'story_steps',
      title: 'Cac buoc cau chuyen',
      subject: 'letters',
    );

    expect(find.text('Sap xep cac buoc theo thu tu.'), findsWidgets);
    await _arrangeSequence(tester, ['Wake up', 'Brush teeth', 'Eat breakfast']);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Kiểm tra'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    _expectQueuedResult('story_steps', 'ss-lv001');
  });
}

Future<void> _launchGame(
  WidgetTester tester, {
  required String gameId,
  required String title,
  required String subject,
}) async {
  await launchApp(
    tester,
    overrides: _offlineGameOverrides(
      gameId: gameId,
      title: title,
      subject: subject,
    ),
  );
  await tester.tap(find.text('Tiếng Việt'));
  await tester.pumpAndSettle(const Duration(seconds: 2));

  expect(find.text('Chào Mi!'), findsOneWidget);
  expect(find.text(title), findsOneWidget);

  await tester.tap(find.text('Tiếp tục học'));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

List<Override> _offlineGameOverrides({
  required String gameId,
  required String title,
  required String subject,
}) {
  final dbGameId = _dbGameId(gameId);
  return [
    apiServiceProvider.overrideWithValue(_FailingGameResultApiService()),
    authProvider.overrideWith(() => _AuthenticatedAuthNotifier()),
    activeChildProvider.overrideWith(
      () => _FixedActiveChildNotifier(_fakeActiveChild()),
    ),
    dailyPlanProvider.overrideWith(
      (ref) async => [
        {
          'lesson_id': 'lesson-$gameId',
          'title': title,
          'subject': subject,
          'estimated_minutes': 5,
          'type': 'lesson',
          'is_required': true,
          'game_type': gameId,
        },
      ],
    ),
    gamesCatalogProvider.overrideWith(
      (ref) async => [
        {
          'id': dbGameId,
          'name': title,
          'game_type': gameId,
          'age_min': 4,
          'age_max': 9,
          'is_active': true,
        },
      ],
    ),
    connectivityProvider.overrideWith((ref) async => false),
  ];
}

Future<void> _tapAll(WidgetTester tester, List<String> labels) async {
  for (final label in labels) {
    await tester.tap(find.text(label).first);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
  }
}

Future<void> _tapCheckAnswers(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(ElevatedButton, 'Kiem tra'));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

Future<void> _placeAll(
  WidgetTester tester,
  Map<String, String> itemToTarget,
) async {
  for (final entry in itemToTarget.entries) {
    final item = find.text(entry.key).first;
    await tester.ensureVisible(item);
    await tester.tap(item);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    final target = find.text(entry.value).first;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
  }
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

Future<void> _matchAll(
  WidgetTester tester,
  Map<String, String> leftToRight,
) async {
  for (final entry in leftToRight.entries) {
    await tester.tap(find.text(entry.key).first);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    await tester.tap(find.text(entry.value).first);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
  }
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

Future<void> _arrangeSequence(
  WidgetTester tester,
  List<String> desiredOrder,
) async {
  for (var desiredIndex = 0;
      desiredIndex < desiredOrder.length;
      desiredIndex++) {
    final label = desiredOrder[desiredIndex];
    while (_sequenceIndex(tester, label, desiredOrder) > desiredIndex) {
      await tester.tap(
        find.descendant(
          of: find.ancestor(
            of: find.text(label),
            matching: find.byType(ListTile),
          ),
          matching: find.byTooltip('Di chuyển sang trái'),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
    }
  }
}

int _sequenceIndex(
  WidgetTester tester,
  String label,
  List<String> visibleLabels,
) {
  final positions = [
    for (final visibleLabel in visibleLabels)
      MapEntry(visibleLabel, tester.getTopLeft(find.text(visibleLabel)).dy),
  ]..sort((a, b) => a.value.compareTo(b.value));
  return positions.indexWhere((entry) => entry.key == label);
}

void _expectQueuedResult(String gameId, String levelId) {
  final item = _queuedGameResult(gameId);
  expect(item, isNotNull);
  expect(item!.childProfileId, TestIds.childA);
  expect(item.payload['game_id'], _dbGameId(gameId));
  expect(item.payload['level_id'], levelId);
  expect(item.payload['completed'], isTrue);
  expect(item.payload['mastery_evidence'], 1.0);
}

SyncQueueItem? _queuedGameResult(String gameId) {
  final dbGameId = _dbGameId(gameId);
  final box = Hive.box<SyncQueueItem>(MiBoxes.syncQueue);
  return box.values.cast<SyncQueueItem?>().firstWhere(
        (item) =>
            item?.type ==
                SyncQueueItem.typeToWireValue(SyncItemType.gameResult) &&
            item?.payload['game_id'] == dbGameId,
        orElse: () => null,
      );
}

String _dbGameId(String gameId) => 'game-${gameId.replaceAll('_', '-')}';

ActiveChildState _fakeActiveChild() => const ActiveChildState(
      childId: TestIds.childA,
      child: {'id': TestIds.childA, 'nickname': 'Mi', 'age_group': 'junior'},
      children: [
        {'id': TestIds.childA, 'nickname': 'Mi', 'age_group': 'junior'},
      ],
    );

class _AuthenticatedAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return const AuthState(isAuthenticated: true);
  }

  @override
  Future<void> initialize() async {
    state = const AuthState(isAuthenticated: true);
  }
}

class _FixedActiveChildNotifier extends ActiveChildNotifier {
  _FixedActiveChildNotifier(this._state);

  final ActiveChildState _state;

  @override
  ActiveChildState build() => _state;

  @override
  Future<void> loadChildren() async {
    state = _state;
  }
}

class _FailingGameResultApiService extends ApiService {
  _FailingGameResultApiService()
      : super(baseUrl: 'http://127.0.0.1:9', tokenStore: InMemoryTokenStore());

  @override
  Future<Map<String, dynamic>> submitGameResult(
    String gameId,
    Map<String, dynamic> result,
  ) async {
    throw StateError('offline integration test blocks public backend calls');
  }
}
