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

/// Standalone Android emulator scenario for Game 11 (Shape Builder) --
/// mirrors alphabet_explorer_flow_test.dart / missing_letter_flow_test.dart
/// exactly (launch through the real production route, not by mounting
/// ShapeBuilderScreen directly).
///
/// Requires the accompanying "chore(integration-only): register Games 11
/// and 12" commit to be applied (the `shape_builder` GameRegistry entry)
/// -- this test drives the daily-plan/game_type path, which resolves the
/// game through the shared registry, not through this test file itself.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await resetLocalState();
  });

  testWidgets(
      'Shape Builder completes from the real home route and queues offline progress after relaunch',
      (tester) async {
    final overrides = _offlineShapeBuilderOverrides();

    await launchApp(tester, overrides: overrides);
    await tester.tap(find.text('Tiếng Việt'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Chào Mi!'), findsOneWidget);
    expect(find.text('Xây hình khối'), findsOneWidget);

    await tester.tap(find.text('Tiếp tục học'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Đặt mỗi hình vào đúng ô của nó!'), findsOneWidget);

    await tester.tap(find.text('Hình tam giác'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Ô của hình tam giác'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Hình thoi'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Ô của hình thoi'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Con làm rất tốt!'), findsOneWidget);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });

    final beforeRelaunch = _queuedShapeBuilderResult();
    expect(beforeRelaunch, isNotNull);
    expect(beforeRelaunch!.childProfileId, TestIds.childA);
    expect(beforeRelaunch.payload['game_id'], 'game-shape-builder');
    expect(beforeRelaunch.payload['level_id'], 'sb-lv001');
    expect(beforeRelaunch.payload['completed'], isTrue);

    await tester.tap(find.text('Thoát'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await launchApp(tester, overrides: overrides);
    expect(find.text('Chào Mi!'), findsOneWidget);

    final afterRelaunch = _queuedShapeBuilderResult();
    expect(afterRelaunch, isNotNull);
    expect(afterRelaunch!.payload['attempt_id'],
        beforeRelaunch.payload['attempt_id']);
    expect(afterRelaunch.payload['level_id'], 'sb-lv001');
  });
}

List<Override> _offlineShapeBuilderOverrides() {
  return [
    apiServiceProvider.overrideWithValue(_FailingGameResultApiService()),
    authProvider.overrideWith(() => _AuthenticatedAuthNotifier()),
    activeChildProvider.overrideWith(
      () => _FixedActiveChildNotifier(_fakeActiveChild()),
    ),
    dailyPlanProvider.overrideWith((ref) async => [
          {
            'lesson_id': 'lesson-shape-builder',
            'title': 'Xây hình khối',
            'subject': 'logic',
            'estimated_minutes': 5,
            'type': 'lesson',
            'is_required': true,
            'game_type': 'shape_builder',
          },
        ]),
    gamesCatalogProvider.overrideWith((ref) async => [
          {
            'id': 'game-shape-builder',
            'name': 'Xây hình khối',
            'game_type': 'shape_builder',
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

SyncQueueItem? _queuedShapeBuilderResult() {
  final box = Hive.box<SyncQueueItem>(MiBoxes.syncQueue);
  return box.values.cast<SyncQueueItem?>().firstWhere(
        (item) =>
            item?.type ==
                SyncQueueItem.typeToWireValue(SyncItemType.gameResult) &&
            item?.payload['game_id'] == 'game-shape-builder',
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
