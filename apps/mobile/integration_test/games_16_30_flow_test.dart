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

  testWidgets('Game 16 Picture Detective completes offline', (tester) async {
    await _launchGame(
      tester,
      gameId: 'picture_detective',
      title: 'Tham tu hinh anh',
      subject: 'science',
    );
    await _matchAll(tester, {
      'giay': 'bong giay',
      'la cay': 'anh la cay',
      'coc': 'net coc',
      'thia': 'net thia',
    });
    _expectQueuedResult('picture_detective', 'pd-lv001');
  });

  testWidgets('Game 17 Color Builder completes offline', (tester) async {
    await _launchGame(
      tester,
      gameId: 'color_builder',
      title: 'Xay mau sac',
      subject: 'creative',
    );
    await _placeEntries(tester, const [
      ('do', 'mau nong'),
      ('vang', 'mau nong'),
      ('cam', 'mau nong'),
      ('xanh duong', 'mau mat'),
      ('xanh la', 'mau mat'),
      ('tim', 'mau mat'),
    ]);
    _expectQueuedResult('color_builder', 'cb-lv001');
  });

  testWidgets('Game 18 Animal Homes completes offline', (tester) async {
    await _launchGame(
      tester,
      gameId: 'animal_homes',
      title: 'Nha cua dong vat',
      subject: 'science',
    );
    await _matchAll(tester, {
      'ca': 'ao',
      'ong': 'to ong',
      'tho': 'hang tho',
      'chim': 'to chim',
    });
    _expectQueuedResult('animal_homes', 'ah-lv001');
  });

  testWidgets('Game 19 Daily Routine completes offline', (tester) async {
    await _launchGame(
      tester,
      gameId: 'daily_routine',
      title: 'Sinh hoat hang ngay',
      subject: 'science',
    );
    await _arrangeSequence(tester, ['Thuc day', 'Danh rang', 'An sang']);
    await _submitSequence(tester);
    _expectQueuedResult('daily_routine', 'dr-lv001');
  });

  testWidgets('Game 20 Healthy Foods completes offline', (tester) async {
    await _launchGame(
      tester,
      gameId: 'healthy_foods',
      title: 'Thuc pham lanh manh',
      subject: 'science',
    );
    await _tapAll(tester, ['tao', 'ca rot', 'nuoc']);
    await _tapCheckAnswers(tester);
    _expectQueuedResult('healthy_foods', 'hf-lv001');
  });

  testWidgets('Game 21 Letter Hunt completes offline', (tester) async {
    await _launchGame(
      tester,
      gameId: 'letter_hunt',
      title: 'San tim chu cai',
      subject: 'letters',
    );
    await _placeEntries(tester, const [
      ('m', 'm-e-o'),
      ('e', 'm-e-o'),
      ('o', 'm-e-o'),
      ('c', 'c-h-o'),
      ('h', 'c-h-o'),
      ('o', 'c-h-o'),
    ]);
    _expectQueuedResult('letter_hunt', 'lh-lv001');
  });

  testWidgets('Game 22 Number Train completes offline', (tester) async {
    await _launchGame(
      tester,
      gameId: 'number_train',
      title: 'Doan tau so',
      subject: 'math',
    );
    await _arrangeSequence(tester, ['1', '2', '3']);
    await _submitSequence(tester);
    _expectQueuedResult('number_train', 'nt-lv001');
  });

  testWidgets('Game 23 Emotion Match completes offline', (tester) async {
    await _launchGame(
      tester,
      gameId: 'emotion_match',
      title: 'Ghep cam xuc',
      subject: 'science',
    );
    await _matchAll(tester, {
      'mat buon': 'nuoc mat',
      'mat gian': 'nhan mat',
      'ngac nhien': 'mat tron',
      'mat vui': 'nu cuoi',
    });
    _expectQueuedResult('emotion_match', 'em-lv001');
  });

  testWidgets('Game 24 Puzzle Parts completes offline', (tester) async {
    await _launchGame(
      tester,
      gameId: 'puzzle_parts',
      title: 'Manh ghep do vat',
      subject: 'creative',
    );
    await _placeEntries(tester, const [
      ('banh xe', 'xe dap'),
      ('yen xe', 'xe dap'),
      ('tay lai', 'xe dap'),
      ('mai nha', 'ngoi nha'),
      ('cua', 'ngoi nha'),
      ('cua so', 'ngoi nha'),
    ]);
    _expectQueuedResult('puzzle_parts', 'pp2-lv001');
  });

  testWidgets('Game 25 Odd One Out completes offline', (tester) async {
    await _launchGame(
      tester,
      gameId: 'odd_one_out',
      title: 'Tim vat khac nhom',
      subject: 'logic',
    );
    await _tapAll(tester, ['ghe', 'thia', 'giay']);
    await _tapCheckAnswers(tester);
    _expectQueuedResult('odd_one_out', 'ooo-lv001');
  });

  testWidgets('Game 26 Opposites completes offline', (tester) async {
    await _launchGame(
      tester,
      gameId: 'opposites',
      title: 'Cap tu trai nghia',
      subject: 'letters',
    );
    await _matchAll(tester, {
      'to': 'nho',
      'nhanh': 'cham',
      'ngay': 'dem',
      'nong': 'lanh',
    });
    _expectQueuedResult('opposites', 'op-lv001');
  });

  testWidgets('Game 27 Weather Today completes offline', (tester) async {
    await _launchGame(
      tester,
      gameId: 'weather_today',
      title: 'Thoi tiet hom nay',
      subject: 'science',
    );
    await _matchAll(tester, {
      'tuyet': 'ao am',
      'nang': 'mu',
      'gio': 'dieu',
      'mua': 'o',
    });
    _expectQueuedResult('weather_today', 'wt-lv001');
  });

  testWidgets('Game 28 Memory Journey completes offline', (tester) async {
    await _launchGame(
      tester,
      gameId: 'memory_journey',
      title: 'Hanh trinh ghi nho',
      subject: 'logic',
    );
    await _arrangeSequence(tester, ['Xep cap', 'Len xe buyt', 'Tham bao tang']);
    await _submitSequence(tester);
    _expectQueuedResult('memory_journey', 'mj-lv001');
  });

  testWidgets('Game 29 Category Expert completes offline', (tester) async {
    await _launchGame(
      tester,
      gameId: 'category_expert',
      title: 'Chuyen gia phan loai',
      subject: 'logic',
    );
    await _tapAll(tester, ['but chi', 'sach', 'thuoc']);
    await _tapCheckAnswers(tester);
    _expectQueuedResult('category_expert', 'ce-lv001');
  });

  testWidgets('Game 30 Build the Story completes offline', (tester) async {
    await _launchGame(
      tester,
      gameId: 'build_the_story',
      title: 'Xay cau chuyen',
      subject: 'letters',
    );
    await _arrangeSequence(tester, ['Tim hat', 'Gieo hat', 'Tuoi nuoc']);
    await _submitSequence(tester);
    _expectQueuedResult('build_the_story', 'bts-lv001');
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
          'age_max': 12,
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

Future<void> _submitSequence(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(ElevatedButton, 'Kiểm tra'));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

Future<void> _placeEntries(
  WidgetTester tester,
  List<(String, String)> itemToTarget,
) async {
  for (final (itemLabel, targetLabel) in itemToTarget) {
    final item = find.text(itemLabel).first;
    await tester.ensureVisible(item);
    await tester.tap(item);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    final target = find.text(targetLabel).first;
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
