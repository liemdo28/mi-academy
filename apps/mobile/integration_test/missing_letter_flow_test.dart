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

  testWidgets(
      'Missing Letter completes from the real home route and queues offline progress after relaunch',
      (tester) async {
    final overrides = _offlineMissingLetterOverrides();

    await launchApp(tester, overrides: overrides);
    await tester.tap(find.text('Tiếng Việt'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Chào Mi!'), findsOneWidget);
    expect(find.text('Tìm chữ còn thiếu'), findsOneWidget);

    await tester.tap(find.text('Tiếp tục học'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Tìm chữ còn thiếu'), findsOneWidget);
    expect(find.text('Chọn chữ còn thiếu: M_O'), findsOneWidget);

    await tester.tap(find.text('È'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Con đã tìm được chữ còn thiếu!'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });

    final beforeRelaunch = _queuedMissingLetterResult();
    expect(beforeRelaunch, isNotNull);
    expect(beforeRelaunch!.childProfileId, TestIds.childA);
    expect(beforeRelaunch.payload['game_id'], 'game-missing-letter');
    expect(beforeRelaunch.payload['level_id'], 'ml-lv001');
    expect(beforeRelaunch.payload['completed'], isTrue);
    expect(beforeRelaunch.payload['mastery_evidence'], 1.0);
    expect(
      beforeRelaunch.payload['skill_evidence'],
      containsPair('letters.spelling', true),
    );

    await tester.tap(find.text('Trang chính'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await launchApp(tester, overrides: overrides);
    expect(find.text('Chào Mi!'), findsOneWidget);

    final afterRelaunch = _queuedMissingLetterResult();
    expect(afterRelaunch, isNotNull);
    expect(afterRelaunch!.payload['attempt_id'],
        beforeRelaunch.payload['attempt_id']);
    expect(afterRelaunch.payload['level_id'], 'ml-lv001');
  });
}

List<Override> _offlineMissingLetterOverrides() {
  return [
    apiServiceProvider.overrideWithValue(_FailingGameResultApiService()),
    authProvider.overrideWith(() => _AuthenticatedAuthNotifier()),
    activeChildProvider.overrideWith(
      () => _FixedActiveChildNotifier(_fakeActiveChild()),
    ),
    dailyPlanProvider.overrideWith((ref) async => [
          {
            'lesson_id': 'lesson-missing-letter',
            'title': 'Tìm chữ còn thiếu',
            'subject': 'letters',
            'estimated_minutes': 5,
            'type': 'lesson',
            'is_required': true,
            'game_type': 'missing_letter',
          },
        ]),
    gamesCatalogProvider.overrideWith((ref) async => [
          {
            'id': 'game-missing-letter',
            'name': 'Tìm chữ còn thiếu',
            'game_type': 'missing_letter',
            'age_min': 6,
            'age_max': 9,
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

SyncQueueItem? _queuedMissingLetterResult() {
  final box = Hive.box<SyncQueueItem>(MiBoxes.syncQueue);
  return box.values.cast<SyncQueueItem?>().firstWhere(
        (item) =>
            item?.type ==
                SyncQueueItem.typeToWireValue(SyncItemType.gameResult) &&
            item?.payload['game_id'] == 'game-missing-letter',
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
