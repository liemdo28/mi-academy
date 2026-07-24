import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_academy/providers/child_provider.dart';
import 'package:mi_academy/providers/providers.dart';
import 'package:mi_academy/screens/parent_dashboard_screen.dart';
import 'package:mi_academy/services/world_progression_service.dart';

/// Covers the new "Hành trình học tập" (Learning Journey) section added
/// to the parent dashboard -- overrides [learningInsightsProvider] and
/// [worldProgressProvider] directly with fixed data rather than driving
/// the real mastery/resolver/asset chain, since that chain is already
/// covered by `world_progression_service_test.dart` and
/// `world_map_screen_test.dart`; this test is purely about whether the
/// dashboard renders what the service hands it.
class _FixedActiveChildNotifier extends ActiveChildNotifier {
  _FixedActiveChildNotifier(this._state);
  final ActiveChildState _state;
  @override
  ActiveChildState build() => _state;
}

Widget _buildDashboard({required LearningInsights insights}) {
  return ProviderScope(
    overrides: [
      reportsProvider.overrideWith((ref) async => []),
      activeChildProvider.overrideWith(
        () => _FixedActiveChildNotifier(const ActiveChildState(children: [])),
      ),
      learningInsightsProvider.overrideWith((ref) async => insights),
      worldProgressProvider.overrideWith((ref) async => const [
            WorldProgress(
                subjectId: 'math',
                name: {'vi': 'Toán học', 'en': 'Math'},
                nodes: []),
          ]),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(
              path: '/dashboard',
              builder: (context, state) => const ParentDashboardScreen()),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets(
      'shows mastered/review/streak/accuracy stats from real '
      'insights data', (tester) async {
    await tester.pumpWidget(_buildDashboard(
      insights: const LearningInsights(
        masteredSkills: [
          SkillInsight(
              skillId: 'math.addition',
              name: {'vi': 'Phép cộng', 'en': 'Addition'},
              masteryScore: 0.9),
        ],
        skillsNeedingReview: [
          SkillInsight(
              skillId: 'logic.memory',
              name: {'vi': 'Ghi nhớ', 'en': 'Memory'},
              masteryScore: 0.4),
        ],
        weakSkills: [
          SkillInsight(
              skillId: 'logic.memory',
              name: {'vi': 'Ghi nhớ', 'en': 'Memory'},
              masteryScore: 0.4),
        ],
        strongSkills: [
          SkillInsight(
              skillId: 'math.addition',
              name: {'vi': 'Phép cộng', 'en': 'Addition'},
              masteryScore: 0.9),
        ],
        curriculumCompletionBySubject: {'math': 0.5},
        streakDays: 3,
        totalTimeSpent: Duration(minutes: 42),
        overallAccuracy: 0.75,
        unlockedRewards: [],
      ),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('Hành trình học tập'), findsOneWidget);
    expect(
        find.text('1'), findsWidgets); // mastered count + review count both 1
    expect(find.text('3'), findsOneWidget); // streak days
    expect(find.text('75%'), findsOneWidget); // accuracy
    expect(find.text('42'), findsOneWidget); // minutes
    expect(find.text('Ghi nhớ'), findsOneWidget); // weak skill chip
    expect(find.text('Toán học'), findsOneWidget); // curriculum bar label
  });

  testWidgets(
      'shows an honest empty summary when no mastery evidence '
      'exists yet -- no fabricated numbers', (tester) async {
    await tester.pumpWidget(_buildDashboard(
      insights: const LearningInsights(
        masteredSkills: [],
        skillsNeedingReview: [],
        weakSkills: [],
        strongSkills: [],
        curriculumCompletionBySubject: {'math': null},
        streakDays: 0,
        totalTimeSpent: Duration.zero,
        overallAccuracy: 0.0,
        unlockedRewards: [],
      ),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('Kỹ năng cần luyện thêm'), findsNothing);
    expect(find.text('Tiến độ chương trình học'), findsNothing);
    expect(find.text('Huy hiệu đã đạt được'), findsNothing);
    expect(find.text('0%'), findsOneWidget);
  });
}
