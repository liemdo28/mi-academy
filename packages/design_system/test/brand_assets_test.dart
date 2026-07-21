import 'dart:io';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mi Academy brand assets', () {
    test('registry exposes all approved mascot emotions', () {
      expect(MiMascotEmotion.values, hasLength(12));
      expect(
        MiMascotEmotion.values,
        containsAll(const [
          MiMascotEmotion.welcome,
          MiMascotEmotion.success,
          MiMascotEmotion.thinking,
          MiMascotEmotion.confused,
          MiMascotEmotion.excited,
          MiMascotEmotion.encouraging,
          MiMascotEmotion.tryAgain,
          MiMascotEmotion.celebration,
          MiMascotEmotion.apology,
          MiMascotEmotion.love,
          MiMascotEmotion.sleeping,
          MiMascotEmotion.surprised,
        ]),
      );
    });

    test('production paths and placeholder fallbacks stay separated', () {
      for (final variant in MiLogoVariant.values) {
        expect(MiBrandAssets.logo(variant), contains('/logo/'));
        expect(MiBrandAssets.logo(variant), isNot(contains('/placeholders/')));
        expect(MiBrandAssets.logoFallback(variant), contains('/placeholders/'));
      }

      for (final emotion in MiMascotEmotion.values) {
        expect(MiBrandAssets.mascot(emotion), contains('/mascot/'));
        expect(
            MiBrandAssets.mascot(emotion), isNot(contains('/placeholders/')));
        expect(
          MiBrandAssets.mascotFallback(emotion),
          contains('/placeholders/'),
        );
      }

      for (final icon in MiBrandIcon.values) {
        expect(MiBrandAssets.brandIcon(icon), contains('/icons/'));
        expect(
          MiBrandAssets.brandIcon(icon),
          isNot(contains('/placeholders/')),
        );
        expect(
            MiBrandAssets.brandIconFallback(icon), contains('/placeholders/'));
      }

      expect(
          File('assets/branding/placeholders/logo_placeholder.svg')
              .existsSync(),
          isTrue);
      expect(
        File('assets/branding/placeholders/mascot_placeholder.svg')
            .existsSync(),
        isTrue,
      );
    });

    testWidgets('logo variants render with fallback placeholders',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Wrap(
              children: [
                MiAcademyLogo(variant: MiLogoVariant.primary),
                MiAcademyLogo(variant: MiLogoVariant.stacked),
                MiAcademyLogo(variant: MiLogoVariant.symbol),
                MiAcademyLogo(variant: MiLogoVariant.monochrome),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MiAcademyLogo), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('all brand icons render with fallback placeholders',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Wrap(
              children: [
                for (final icon in MiBrandIcon.values)
                  MiBrandIconView(
                    icon: icon,
                    size: MiTokens.iconMd,
                    semanticLabel: icon.assetName,
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MiBrandIconView),
          findsNWidgets(MiBrandIcon.values.length));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'brand icon supports semantics, decorative, disabled, and dark surface',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                MiBrandIconView(
                  icon: MiBrandIcon.alphabet,
                  semanticLabel: 'Letters category',
                ),
                MiBrandIconView(
                  icon: MiBrandIcon.profile,
                  semanticLabel: 'Hidden profile',
                  decorative: true,
                ),
                MiBrandIconView(
                  icon: MiBrandIcon.rewardStar,
                  enabled: false,
                ),
                ColoredBox(
                  color: MiColors.navy,
                  child: MiBrandIconView(
                    icon: MiBrandIcon.world,
                    darkSurface: true,
                    semanticLabel: 'World category',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Letters category'), findsOneWidget);
      expect(find.bySemanticsLabel('Hidden profile'), findsNothing);
      expect(find.bySemanticsLabel('World category'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('all mascot emotions render with fallback placeholders',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Wrap(
              children: [
                for (final emotion in MiMascotEmotion.values)
                  MiMascotReaction(
                    emotion: emotion,
                    size: MiTokens.mascotReactionSm,
                    semanticLabel: emotion.assetName,
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MiMascotReaction), findsNWidgets(12));
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion disables mascot animation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: MiMascotReaction(
                emotion: MiMascotEmotion.excited,
                animationMode: MiBrandAnimationMode.subtle,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedScale), findsNothing);
    });

    testWidgets('mascot semantics can be labeled or decorative',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MiMascotReaction(
                  emotion: MiMascotEmotion.success,
                  semanticLabel: 'MI celebrates with the child',
                ),
                MiMascotReaction(
                  emotion: MiMascotEmotion.sleeping,
                  semanticLabel: 'hidden mascot',
                  decorative: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('MI celebrates with the child'),
          findsOneWidget);
      expect(find.bySemanticsLabel('hidden mascot'), findsNothing);
    });

    testWidgets('Vietnamese and English messages fit phone and tablet widths',
        (tester) async {
      for (final size in const [Size(390, 844), Size(834, 1112)]) {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  MiMascotReaction(
                    emotion: MiMascotEmotion.encouraging,
                    message: 'Cố lên, mình học tiếp nhé!',
                  ),
                  MiMascotReaction(
                    emotion: MiMascotEmotion.encouraging,
                    message: 'Keep going, learning buddy!',
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      }
    });

    test('migrated feature code uses registry/components, not raw brand paths',
        () {
      final migratedFiles = [
        File('../../apps/mobile/lib/screens/child_home_screen.dart'),
        File('../../apps/mobile/lib/screens/child_selector_screen.dart'),
        File('../../apps/mobile/lib/screens/world_map_screen.dart'),
        File('../../apps/mobile/lib/screens/garden_screen.dart'),
        File('../../apps/mobile/lib/screens/parent_dashboard_screen.dart'),
        File('../../apps/mobile/lib/screens/parent_settings_screen.dart'),
        File('../../apps/mobile/lib/main.dart'),
        File('../../apps/mobile/lib/services/game_registry.dart'),
        File('../../apps/mobile/lib/src/games/choice/choice_game_screen.dart'),
        File('../mi_game_ui/lib/src/widgets/completion_overlay.dart'),
        File('../mi_game_ui/lib/src/widgets/error_state.dart'),
        File('../mi_game_ui/lib/src/widgets/game_header.dart'),
        File('../mi_game_ui/lib/src/widgets/loading_state.dart'),
        File('../mi_game_ui/lib/src/widgets/retry_prompt.dart'),
        File('../mi_game_ui/lib/src/widgets/tutorial_overlay.dart'),
        File('../mi_game_engines/lib/src/matching/matching_screen.dart'),
        File('../mi_game_engines/lib/src/sequence/sequence_screen.dart'),
        File('../mi_game_engines/lib/src/placement/placement_screen.dart'),
      ];

      for (final file in migratedFiles) {
        expect(file.existsSync(), isTrue, reason: file.path);
        final source = file.readAsStringSync();
        expect(source, isNot(contains('assets/branding/')), reason: file.path);
        expect(source, isNot(contains('SvgPicture')), reason: file.path);
      }
    });

    test('deprecated mascot compatibility API has been removed', () {
      final source =
          File('lib/src/widgets/mi_brand_components.dart').readAsStringSync();
      expect(source, isNot(contains('MiMascotReactionType')));
      expect(source, isNot(contains('reaction?._emotion')));
    });
  });
}
