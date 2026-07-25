import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/src/games/free_creativity/free_creativity_screen.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_ui/mi_game_ui.dart';

void main() {
  testWidgets('Free Creativity completes through creative participation',
      (tester) async {
    _usePhoneViewport(tester);
    MiCompletionResult? completed;

    await tester.pumpWidget(
      MaterialApp(
        home: FreeCreativityScreen(
          level: _creativeLevel,
          allLevels: const [_creativeLevel],
          locale: 'en',
          onComplete: (result) => completed = result,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Free Creativity'), findsOneWidget);
    expect(
      find.text(
        'There is no wrong answer here. Build your own idea!',
        skipOffstage: false,
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Share story'));
    await tester.pump();
    expect(
      find.text('Choose a scene for your story.', skipOffstage: false),
      findsOneWidget,
    );
    expect(completed, isNull);

    await tester.tap(find.text('A tiny door'));
    await tester.pump();
    await tester.tap(find.text('MI').last);
    await tester.pump();
    await tester.tap(find.text('curious'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('free-creativity-story-field')),
      'MI opens the door and finds a kind idea.',
    );
    await tester.pump();
    await tester.tap(find.text('Share story'));
    await tester.pump();

    expect(completed, isNotNull);
    expect(completed!.metadata['completionModel'], 'participation');
    expect(completed!.metadata['engine'], 'creative_story_lab');
    expect(find.text('Your story idea is taking shape!'), findsOneWidget);
  });

  testWidgets('Free Creativity supports Vietnamese hint and clear idea',
      (tester) async {
    _usePhoneViewport(tester);

    await tester.pumpWidget(
      const MaterialApp(
        home: FreeCreativityScreen(
          level: _creativeLevel,
          allLevels: [_creativeLevel],
          locale: 'vi',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Sáng tạo tự do'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('free-creativity-story-field')),
      'MI hỏi điều gì ở sau cánh cửa?',
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Xóa ý tưởng'));
    await tester.pump();
    await tester.tap(find.text('Xóa ý tưởng'));
    await tester.pump();
    expect(find.text('MI hỏi điều gì ở sau cánh cửa?'), findsNothing);

    await tester.tap(find.byType(HintButton));
    await tester.pump();
    expect(
      find.text(
        'Thử viết một câu về chuyện xảy ra tiếp theo nhé.',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(480, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

const _creativeLevel = MiLevel(
  id: 'free-creativity-test',
  gameId: 'free_creativity',
  levelNumber: 1,
  difficulty: 1,
  localizedContent: {
    'vi': {
      'prompt': 'Tạo câu chuyện tò mò.',
      'options': [
        {'id': 'a', 'text': 'Một cánh cửa nhỏ', 'correct': false},
        {'id': 'b', 'text': 'tiếng gõ nhẹ', 'correct': false},
        {'id': 'c', 'text': 'một câu hỏi mới', 'correct': true},
      ],
      'deepData': {
        'storyCards': ['Một cánh cửa nhỏ', 'tiếng gõ nhẹ', 'một câu hỏi mới'],
      },
    },
    'en': {
      'prompt': 'Create a curious story.',
      'options': [
        {'id': 'a', 'text': 'A tiny door', 'correct': false},
        {'id': 'b', 'text': 'a gentle knock', 'correct': false},
        {'id': 'c', 'text': 'a new question', 'correct': true},
      ],
      'deepData': {
        'storyCards': ['A tiny door', 'a gentle knock', 'a new question'],
      },
    },
  },
  hints: [
    {
      'localizedText': {
        'vi': 'Thử viết một câu về chuyện xảy ra tiếp theo nhé.',
        'en': 'Try one sentence about what happens next.',
      },
    },
  ],
  metadata: {
    'skillIds': ['creative.storytelling'],
    'deepData': {
      'scene': 'creative',
      'targetFeeling': 'curious',
    },
  },
);
