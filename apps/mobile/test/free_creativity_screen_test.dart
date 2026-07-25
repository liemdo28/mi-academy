import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/src/games/free_creativity/creative_artifact_store.dart';
import 'package:mi_academy/src/games/free_creativity/free_creativity_screen.dart';
import 'package:mi_academy/src/games/free_creativity/free_creativity_session.dart';
import 'package:mi_game_audio/mi_game_audio.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_ui/mi_game_ui.dart';

void main() {
  testWidgets('Free Creativity completes as ungraded participation',
      (tester) async {
    _usePhoneViewport(tester);
    MiCompletionResult? completed;
    final store = InMemoryCreativeArtifactStore();
    final audioIntents = <MiAudioIntent>[];

    await tester.pumpWidget(
      MaterialApp(
        home: FreeCreativityScreen(
          level: _creativeLevel,
          allLevels: const [_creativeLevel],
          childProfileId: 'child-live',
          locale: 'en',
          artifactStore: store,
          playAudioIntent: (intent) async => audioIntents.add(intent),
          onComplete: (result) => completed = result,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Free Creativity'), findsOneWidget);
    expect(
      find.text(
        'Build your own story idea. MI is ready to listen!',
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
    expect(audioIntents.last, MiAudioIntent.gentleAttention);
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
    await tester.pumpAndSettle();

    expect(audioIntents, contains(MiAudioIntent.selectionSoft));
    expect(audioIntents.last, MiAudioIntent.creativeComplete);
    expect(audioIntents, isNot(contains(MiAudioIntent.correct)));
    expect(audioIntents, isNot(contains(MiAudioIntent.incorrect)));
    expect(completed, isNotNull);
    expect(completed!.childProfileId, 'child-live');
    expect(completed!.perfectRun, isFalse);
    expect(completed!.metadata['completionModel'], 'participation');
    expect(completed!.metadata['assessmentModel'], 'ungraded');
    expect(completed!.metadata['isMasteryScore'], isFalse);
    expect(completed!.metadata['isQualityScore'], isFalse);
    expect(completed!.metadata['artifactId'], isNotNull);
    expect(completed!.metadata.containsKey('storyText'), isFalse);
    expect(store.listForChild('child-live'), hasLength(1));
    expect(find.text('Your story idea is taking shape!'), findsOneWidget);
    expect(find.textContaining('Score'), findsNothing);
    expect(find.textContaining('100'), findsNothing);
  });

  testWidgets('Free Creativity shows every missing-participation message',
      (tester) async {
    _usePhoneViewport(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: FreeCreativityScreen(
          level: _creativeLevel,
          allLevels: const [_creativeLevel],
          childProfileId: 'child-guidance',
          locale: 'en',
          artifactStore: InMemoryCreativeArtifactStore(),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Share story'));
    await tester.pump();
    expect(find.text('Choose a scene for your story.', skipOffstage: false),
        findsOneWidget);

    await tester.tap(find.text('A tiny door'));
    await tester.pump();
    await tester.tap(find.text('Share story'));
    await tester.pump();
    expect(find.text('Choose who appears in the story.', skipOffstage: false),
        findsOneWidget);

    await tester.tap(find.text('MI').last);
    await tester.pump();
    await tester.tap(find.text('Share story'));
    await tester.pump();
    expect(
        find.text('Choose the feeling you want to show.', skipOffstage: false),
        findsOneWidget);

    await tester.tap(find.text('curious'));
    await tester.pump();
    await tester.tap(find.text('Share story'));
    await tester.pump();
    expect(find.text('Add a short story idea.', skipOffstage: false),
        findsOneWidget);
  });

  testWidgets('Free Creativity supports Vietnamese hint and clear idea',
      (tester) async {
    _usePhoneViewport(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: FreeCreativityScreen(
          level: _creativeLevel,
          allLevels: const [_creativeLevel],
          childProfileId: 'child-vi',
          locale: 'vi',
          artifactStore: InMemoryCreativeArtifactStore(),
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

  testWidgets('Free Creativity completes in Vietnamese', (tester) async {
    _usePhoneViewport(tester);
    MiCompletionResult? completed;
    final store = InMemoryCreativeArtifactStore();

    await tester.pumpWidget(
      MaterialApp(
        home: FreeCreativityScreen(
          level: _creativeLevel,
          allLevels: const [_creativeLevel],
          childProfileId: 'child-vi',
          locale: 'vi',
          artifactStore: store,
          onComplete: (result) => completed = result,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Một cánh cửa nhỏ'));
    await tester.pump();
    await tester.tap(find.text('MI').last);
    await tester.pump();
    await tester.tap(find.text('tò mò'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('free-creativity-story-field')),
      'MI mở cửa và gặp một ý tưởng mới.',
    );
    await tester.pump();
    await tester.tap(find.text('Chia sẻ câu chuyện'));
    await tester.pumpAndSettle();

    expect(completed, isNotNull);
    expect(store.listForChild('child-vi').single.storyText,
        'MI mở cửa và gặp một ý tưởng mới.');
    expect(find.text('Ý tưởng câu chuyện của con đang thành hình!'),
        findsOneWidget);
  });

  testWidgets('Free Creativity restore uses child identity and stable IDs',
      (tester) async {
    _usePhoneViewport(tester);
    final session = _restoredSession();
    final snapshot = session.saveSnapshot();

    await tester.pumpWidget(
      MaterialApp(
        home: FreeCreativityScreen(
          level: _creativeLevel,
          allLevels: const [_creativeLevel],
          childProfileId: 'child-live',
          locale: 'en',
          initialSnapshot: snapshot,
          artifactStore: InMemoryCreativeArtifactStore(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('A tiny door'), findsOneWidget);
    final selected = tester.widget<Semantics>(
      find
          .ancestor(
            of: find.widgetWithText(OutlinedButton, 'A tiny door'),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(selected.properties.selected, isTrue);
    expect(find.text('Saved story text'), findsOneWidget);
  });

  testWidgets('Free Creativity respects reduce motion', (tester) async {
    _usePhoneViewport(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: FreeCreativityScreen(
          level: _creativeLevel,
          allLevels: const [_creativeLevel],
          childProfileId: 'child-motion',
          locale: 'en',
          reduceMotion: true,
          artifactStore: InMemoryCreativeArtifactStore(),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Share story'));
    await tester.pump();

    final switcher = tester.widget<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher).last,
    );
    expect(switcher.duration, Duration.zero);
  });

  testWidgets('Free Creativity layout has no overflow on tablet English',
      (tester) async {
    _useTabletViewport(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: FreeCreativityScreen(
          level: _creativeLevel,
          allLevels: const [_creativeLevel],
          childProfileId: 'child-tablet',
          locale: 'en',
          artifactStore: InMemoryCreativeArtifactStore(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Free Creativity'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Free Creativity layout handles landscape phone and large text',
      (tester) async {
    tester.view.physicalSize = const Size(900, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(900, 480),
            textScaler: TextScaler.linear(1.5),
          ),
          child: FreeCreativityScreen(
            level: _creativeLevel,
            allLevels: const [_creativeLevel],
            childProfileId: 'child-large-text',
            locale: 'en',
            artifactStore: InMemoryCreativeArtifactStore(),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Share story'));
    expect(find.text('Share story'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Free Creativity remains usable when keyboard is open',
      (tester) async {
    _usePhoneViewport(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(480, 900),
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
          child: FreeCreativityScreen(
            level: _creativeLevel,
            allLevels: const [_creativeLevel],
            childProfileId: 'child-keyboard',
            locale: 'en',
            artifactStore: InMemoryCreativeArtifactStore(),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -360));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('free-creativity-story-field')),
      'Keyboard story text',
    );
    expect(find.text('Keyboard story text'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Free Creativity completion is idempotent on repeated taps',
      (tester) async {
    _usePhoneViewport(tester);
    final store = InMemoryCreativeArtifactStore();
    var completions = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: FreeCreativityScreen(
          level: _creativeLevel,
          allLevels: const [_creativeLevel],
          childProfileId: 'child-double',
          locale: 'en',
          artifactStore: store,
          onComplete: (_) => completions++,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('A tiny door'));
    await tester.pump();
    await tester.tap(find.text('MI').last);
    await tester.pump();
    await tester.tap(find.text('curious'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('free-creativity-story-field')),
      'MI writes one bright idea.',
    );
    await tester.pump();
    await tester.tap(find.text('Share story'));
    await tester.tap(find.text('Share story'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(completions, 1);
    expect(store.listForChild('child-double'), hasLength(1));
  });
}

FreeCreativitySession _restoredSession() {
  final session = FreeCreativitySession(
    level: _creativeLevel,
    childProfileId: 'child-live',
    locale: 'en',
  );
  return session
    ..selectScene('scene-door')
    ..selectCharacter('character-mi')
    ..selectFeeling('feeling-curious')
    ..updateStoryText('Saved story text');
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(480, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _useTabletViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1024, 1366);
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
        'scenes': [
          {'id': 'scene-door', 'label': 'Một cánh cửa nhỏ'}
        ],
        'characters': [
          {'id': 'character-mi', 'label': 'MI'}
        ],
        'feelings': [
          {'id': 'feeling-curious', 'label': 'tò mò'}
        ],
        'minimumStoryLength': 1,
        'maximumStoryLength': 500,
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
        'scenes': [
          {'id': 'scene-door', 'label': 'A tiny door'}
        ],
        'characters': [
          {'id': 'character-mi', 'label': 'MI'}
        ],
        'feelings': [
          {'id': 'feeling-curious', 'label': 'curious'}
        ],
        'minimumStoryLength': 1,
        'maximumStoryLength': 500,
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
      'engine': 'creative_story_lab',
      'completionModel': 'participation',
      'assessmentModel': 'ungraded',
    },
  },
);
