import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:mi_academy/providers/child_provider.dart';
import 'package:mi_academy/providers/providers.dart';
import 'package:mi_academy/screens/child_home_screen.dart';

class _FixedActiveChildNotifier extends ActiveChildNotifier {
  _FixedActiveChildNotifier(this._state);

  final ActiveChildState _state;

  @override
  ActiveChildState build() => _state;
}

void main() {
  group('Child Home brand foundation', () {
    testWidgets('renders the Phase 1 brand structure in Vietnamese',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(834, 1112));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpHome(tester, locale: const Locale('vi'));

      expect(find.byType(MiAcademyLogo), findsOneWidget);
      expect(find.text('Chào Mi!'), findsOneWidget);
      expect(find.text('Chơi, học, lớn lên mỗi ngày'), findsOneWidget);
      expect(find.text('Tiếp tục học'), findsOneWidget);
      expect(find.text('Tiến độ hôm nay'), findsOneWidget);
      expect(find.text('Góc học vui'), findsOneWidget);
      expect(find.byType(MiMascotReaction), findsWidgets);
      expect(find.byType(MiBottomNavigation), findsOneWidget);
      expect(find.textContaining('✨'), findsNothing);
    });

    testWidgets('renders localized Home copy in English', (tester) async {
      await tester.binding.setSurfaceSize(const Size(834, 1112));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpHome(tester, locale: const Locale('en'));

      expect(find.text('Hi Mi!'), findsOneWidget);
      expect(find.text('Play, learn, and grow every day'), findsOneWidget);
      expect(find.text('Continue learning'), findsOneWidget);
      expect(find.text("Today's missions"), findsOneWidget);
      expect(find.text('Learning corner'), findsOneWidget);
    });

    testWidgets('launches the daily plan game type from the hero CTA',
        (tester) async {
      await _pumpHome(tester,
          locale: const Locale('vi'), includeGameRoute: true);

      await tester.tap(find.text('Tiếp tục học'));
      await tester.pumpAndSettle();

      expect(find.text('LAUNCHED_robot_commands'), findsOneWidget);
    });

    testWidgets('phone Vietnamese preview has no overflow', (tester) async {
      await _expectPreview(
        tester,
        locale: const Locale('vi'),
        size: const Size(390, 844),
        goldenName: 'goldens/home_phone_vi.png',
      );
    });

    testWidgets('phone English preview has no overflow', (tester) async {
      await _expectPreview(
        tester,
        locale: const Locale('en'),
        size: const Size(390, 844),
        goldenName: 'goldens/home_phone_en.png',
      );
    });

    testWidgets('tablet Vietnamese preview has no overflow', (tester) async {
      await _expectPreview(
        tester,
        locale: const Locale('vi'),
        size: const Size(834, 1112),
        goldenName: 'goldens/home_tablet_vi.png',
      );
    });

    testWidgets('tablet English preview has no overflow', (tester) async {
      await _expectPreview(
        tester,
        locale: const Locale('en'),
        size: const Size(834, 1112),
        goldenName: 'goldens/home_tablet_en.png',
      );
    });
  });
}

Future<void> _expectPreview(
  WidgetTester tester, {
  required Locale locale,
  required Size size,
  required String goldenName,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await _pumpHome(tester, locale: locale);
  expect(tester.takeException(), isNull);
  await expectLater(
      find.byType(ChildHomeScreen), matchesGoldenFile(goldenName));
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required Locale locale,
  bool includeGameRoute = false,
}) async {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => const ChildHomeScreen(),
      ),
      GoRoute(
        path: '/world',
        builder: (context, state) => const Scaffold(body: Text('WORLD')),
      ),
      GoRoute(
        path: '/garden',
        builder: (context, state) => const Scaffold(body: Text('GARDEN')),
      ),
      GoRoute(
        path: '/parent-pin',
        builder: (context, state) => const Scaffold(body: Text('PARENT_GATE')),
      ),
      if (includeGameRoute)
        GoRoute(
          path: '/game/:gameId',
          builder: (context, state) =>
              Text('LAUNCHED_${state.pathParameters['gameId']}'),
        ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeChildProvider.overrideWith(
          () => _FixedActiveChildNotifier(
            const ActiveChildState(
              childId: 'child-1',
              child: {'id': 'child-1', 'nickname': 'Mi'},
            ),
          ),
        ),
        dailyPlanProvider.overrideWith((ref) async {
          return [
            {
              'lesson_id': 'lesson-1',
              'title': locale.languageCode == 'en'
                  ? 'Logic warm-up'
                  : 'Khởi động tư duy',
              'subject': locale.languageCode == 'en' ? 'logic' : 'logic',
              'estimated_minutes': 5,
              'game_type': 'robot_commands',
            },
          ];
        }),
      ],
      child: MaterialApp.router(
        theme: MiTheme.light,
        locale: locale,
        supportedLocales: supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
