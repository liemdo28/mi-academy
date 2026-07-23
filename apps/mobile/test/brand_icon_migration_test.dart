import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mi Academy brand icon migration', () {
    test('migrated app-shell files do not use raw brand asset paths', () {
      final files = [
        File('lib/screens/child_home_screen.dart'),
        File('lib/screens/child_selector_screen.dart'),
        File('lib/screens/world_map_screen.dart'),
        File('lib/screens/garden_screen.dart'),
        File('lib/screens/parent_dashboard_screen.dart'),
        File('lib/screens/parent_settings_screen.dart'),
        File('lib/main.dart'),
        File('lib/services/game_registry.dart'),
        File('lib/src/games/choice/choice_game_screen.dart'),
      ];

      for (final file in files) {
        expect(file.existsSync(), isTrue, reason: file.path);
        final source = file.readAsStringSync();
        expect(source, isNot(contains('assets/branding/')), reason: file.path);
        expect(source, isNot(contains('SvgPicture')), reason: file.path);
      }
    });

    test('deprecated mascot API is no longer used by app code', () {
      final files = [
        File('lib/screens/child_home_screen.dart'),
        File(
            '../../packages/mi_game_ui/lib/src/widgets/completion_overlay.dart'),
        File('../../packages/mi_game_ui/lib/src/widgets/error_state.dart'),
        File('../../packages/mi_game_ui/lib/src/widgets/loading_state.dart'),
        File('../../packages/mi_game_ui/lib/src/widgets/retry_prompt.dart'),
        File('../../packages/mi_game_ui/lib/src/widgets/tutorial_overlay.dart'),
      ];

      for (final file in files) {
        expect(file.existsSync(), isTrue, reason: file.path);
        expect(
          file.readAsStringSync(),
          isNot(contains('MiMascotReactionType')),
          reason: file.path,
        );
      }
    });

    test('app icon production sources are present and wired', () {
      final requiredConfig = [
        File('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml'),
        File(
            'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml'),
        File('android/app/src/main/res/drawable/ic_launcher_foreground.xml'),
        File('android/app/src/main/res/drawable/ic_launcher_monochrome.xml'),
        File(
          'android/app/src/main/res/drawable/ic_launcher_foreground_placeholder.xml',
        ),
        File(
          'android/app/src/main/res/drawable/ic_launcher_monochrome_placeholder.xml',
        ),
        File('ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json'),
      ];
      for (final file in requiredConfig) {
        expect(file.existsSync(), isTrue, reason: file.path);
      }

      final productionSources = [
        File('../../assets/branding/app_icon/android/foreground.svg'),
        File('../../assets/branding/app_icon/android/background.svg'),
        File('../../assets/branding/app_icon/android/monochrome.svg'),
        File('../../assets/branding/app_icon/android/play_store_512.png'),
        File('../../assets/branding/app_icon/ios/app_icon_master_1024.png'),
      ];
      final missingProductionSources = [
        for (final file in productionSources)
          if (!file.existsSync()) file.path,
      ];
      final emptyProductionSources = [
        for (final file in productionSources)
          if (file.existsSync() && file.lengthSync() == 0) file.path,
      ];

      expect(missingProductionSources, isEmpty);
      expect(emptyProductionSources, isEmpty);

      for (final file in requiredConfig.take(2)) {
        expect(file.readAsStringSync(), isNot(contains('_placeholder')));
      }
    });
  });
}
