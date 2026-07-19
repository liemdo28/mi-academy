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

/// Standalone Android emulator scenario for Game 12 (Word Sorter) --
/// mirrors alphabet_explorer_flow_test.dart / missing_letter_flow_test.dart
/// exactly (launch through the real production route). Requires the
/// accompanying "chore(integration-only): register Games 11 and 12"
/// commit to be applied (the `word_sorter` GameRegistry entry).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await resetLocalState();
  });

  testWidgets(
      'Word Sorter completes from the real home route and queues offline progress after relaunch',
      (tester) async {
    final overrides = _offlineWordSorterOverrides();

    await launchApp(tester, overrides: overrides);
    await tester.tap(find.text('Tiếng Việt'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Chào Mi!'), findsOneWidget);
    expect(find.text('Phân loại từ'), findsOneWidget);

    await tester.tap(find.text('Tiếp tục học'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(
      find.text('Sắp xếp các từ vào đúng nhóm: Đồ chơi và Phương tiện đi lại!'),
      findsOneWidget,
    );

    await tester.tap(find.text('xếp hình'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Đồ chơi'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('gấu bông'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Đồ chơi'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('tàu hỏa'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Phương tiện đi lại'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('ô tô'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Phương tiện đi lại'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Con làm rất tốt!'), findsOneWidget);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });

    final beforeRelaunch = _queuedWordSorterResult();
    expect(beforeRelaunch, isNotNull);
    expect(beforeRelaunch!.childProfileId, TestIds.childA);
    expect(beforeRelaunch.payload['game_id'], 'game-word-sorter');
    expect(beforeRelaunch.payload['level_id'], 'ws-lv001');
    expect(beforeRelaunch.payload['completed'], isTrue);

    await tester.tap(find.text('Thoát'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await launchApp(tester, overrides: overrides);
    expect(find.text('Chào Mi!'), findsOneWidget);

    final afterRelaunch = _queuedWordSorterResult();
    expect(afterRelaunch, isNotNull);
    expect(afterRelaunch!.payload['attempt_id'],
        beforeRelaunch.payload['attempt_id']);
    expect(afterRelaunch.payload['level_id'], 'ws-lv001');
  });
}

List<Override> _offlineWordSorterOverrides() {
  return [
    apiServiceProvider.overrideWithValue(_FailingGameResultApiService()),
    authProvider.overrideWith(() => _AuthenticatedAuthNotifier()),
    activeChildProvider.overrideWith(
      () => _FixedActiveChildNotifier(_fakeActiveChild()),
    ),
    dailyPlanProvider.overrideWith((ref) async => [
          {
            'lesson_id': 'lesson-word-sorter',
            'title': 'Phân loại từ',
            'subject': 'letters',
            'estimated_minutes': 5,
            'type': 'lesson',
            'is_required': true,
            'game_type': 'word_sorter',
          },
        ]),
    gamesCatalogProvider.overrideWith((ref) async => [
          {
            'id': 'game-word-sorter',
            'name': 'Phân loại từ',
            'game_type': 'word_sorter',
            'age_min': 5,
            'age_max': 10,
            'is_active': true,
          },
        ]),
    connectivityProvider.overrideWith((ref) async => false),
  ];
}

ActiveChildState _fakeActiveChild() => const ActiveChildState(
      childId: TestIds.childA,
      child: {
        'id': TestIds.childA,
        'nickname': 'Mi',
        'age_group': 'junior',
      },
      children: [
        {
          'id': TestIds.childA,
          'nickname': 'Mi',
          'age_group': 'junior',
        },
      ],
    );

SyncQueueItem? _queuedWordSorterResult() {
  final box = Hive.box<SyncQueueItem>(MiBoxes.syncQueue);
  return box.values.cast<SyncQueueItem?>().firstWhere(
        (item) =>
            item?.type ==
                SyncQueueItem.typeToWireValue(SyncItemType.gameResult) &&
            item?.payload['game_id'] == 'game-word-sorter',
        orElse: () => null,
      );
}

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
