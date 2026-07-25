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
      'Alphabet Explorer completes from the real home route and queues offline progress after relaunch',
      (tester) async {
    final overrides = _offlineAlphabetExplorerOverrides();

    await launchApp(tester, overrides: overrides);
    await tester.tap(find.text('Tiếng Việt'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Chào Mi!'), findsOneWidget);

    await tester.tap(find.text('Tiếp tục học'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Khám phá chữ cái'), findsWidgets);
    expect(find.text('Tìm chữ A.'), findsOneWidget);

    await tester.tap(find.text('A').last);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('MI thấy con đã hiểu bài!'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });

    final beforeRelaunch = _queuedAlphabetExplorerResult();
    expect(beforeRelaunch, isNotNull);
    expect(beforeRelaunch!.childProfileId, TestIds.childA);
    expect(beforeRelaunch.payload['game_id'], 'game-alphabet-explorer');
    expect(beforeRelaunch.payload['level_id'], 'ae-lv001');
    expect(beforeRelaunch.payload['completed'], isTrue);
    expect(beforeRelaunch.payload['mastery_evidence'], 1.0);
    expect(
      beforeRelaunch.payload['skill_evidence'],
      containsPair('letters.recognition.uppercase', true),
    );

    await tester.tap(find.text('Trang chính'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await launchApp(tester, overrides: overrides);
    expect(find.text('Chào Mi!'), findsOneWidget);

    final afterRelaunch = _queuedAlphabetExplorerResult();
    expect(afterRelaunch, isNotNull);
    expect(afterRelaunch!.payload['attempt_id'],
        beforeRelaunch.payload['attempt_id']);
    expect(afterRelaunch.payload['level_id'], 'ae-lv001');
  });
}

List<Override> _offlineAlphabetExplorerOverrides() {
  return [
    apiServiceProvider.overrideWithValue(_FailingGameResultApiService()),
    authProvider.overrideWith(() => _AuthenticatedAuthNotifier()),
    activeChildProvider.overrideWith(
      () => _FixedActiveChildNotifier(_fakeActiveChild()),
    ),
    dailyPlanProvider.overrideWith((ref) async => [
          {
            'lesson_id': 'lesson-alphabet-explorer',
            'title': 'Khám phá chữ cái',
            'subject': 'letters',
            'estimated_minutes': 5,
            'type': 'lesson',
            'is_required': true,
            'game_type': 'alphabet_explorer',
          },
        ]),
    gamesCatalogProvider.overrideWith((ref) async => [
          {
            'id': 'game-alphabet-explorer',
            'name': 'Khám phá chữ cái',
            'game_type': 'alphabet_explorer',
            'age_min': 4,
            'age_max': 8,
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

SyncQueueItem? _queuedAlphabetExplorerResult() {
  final box = Hive.box<SyncQueueItem>(MiBoxes.syncQueue);
  return box.values.cast<SyncQueueItem?>().firstWhere(
        (item) =>
            item?.type ==
                SyncQueueItem.typeToWireValue(SyncItemType.gameResult) &&
            item?.payload['game_id'] == 'game-alphabet-explorer',
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
