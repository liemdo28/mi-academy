// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/services/game_levels.dart';

void main() {
  testWidgets('debug: load each game via loadGameLevels(context, gameId)',
      (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      ),
    );
    for (final gameId in gameLevelAssets.keys) {
      print('TEMP_CI: loading $gameId');
      try {
        final levels = await loadGameLevels(ctx, gameId);
        print('TEMP_CI: loaded $gameId (${levels.length} levels)');
      } catch (e, st) {
        print('TEMP_CI: FAILED $gameId: $e');
        print('TEMP_CI: stack: $st');
      }
    }
  });

  test('debug: raw rootBundle.loadString for math_race.json', () async {
    print('TEMP_CI: raw load starting');
    final str = await rootBundle.loadString('assets/levels/math_race.json');
    print('TEMP_CI: raw load done, length=${str.length}');
  });
}
