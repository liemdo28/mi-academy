import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mi_academy/src/games/free_creativity/creative_artifact_store.dart';

void main() {
  test('HiveCreativeArtifactStore survives close and reopen', () async {
    final directory = await Directory.systemTemp.createTemp('mi-artifacts-');
    addTearDown(() async {
      await Hive.close();
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
    });

    Hive.init(directory.path);
    var box = await Hive.openBox('creative_artifacts_test');
    final store = HiveCreativeArtifactStore(box);
    final createdAt = DateTime.utc(2026, 7, 25, 8);
    final updatedAt = DateTime.utc(2026, 7, 25, 9);
    final artifact = CreativeArtifact(
      artifactId: 'artifact-1',
      childProfileId: 'child-a',
      gameId: 'free_creativity',
      levelId: 'fc-1',
      sceneId: 'scene-door',
      sceneLabel: 'Một cánh cửa nhỏ',
      characterId: 'character-mi',
      characterLabel: 'MI',
      feelingId: 'feeling-curious',
      feelingLabel: 'tò mò',
      storyText: 'MI mở cửa, cười 😊, và nói xin chào.',
      locale: 'vi',
      createdAt: createdAt,
      updatedAt: updatedAt,
      contentVersion: 7,
      storyStarterId: 'starter-1',
      assetReferences: const ['asset://scene-door'],
    );
    await store.save(artifact);
    await store.save(artifact.copyWith(
      storyText: 'MI mở cửa lần nữa 😊.',
      updatedAt: updatedAt.add(const Duration(minutes: 1)),
      revision: 2,
    ));
    await store.save(CreativeArtifact(
      artifactId: 'artifact-2',
      childProfileId: 'child-b',
      gameId: 'free_creativity',
      levelId: 'fc-1',
      sceneId: 'scene-door',
      sceneLabel: 'A tiny door',
      characterId: 'character-mi',
      characterLabel: 'MI',
      feelingId: 'feeling-happy',
      feelingLabel: 'happy',
      storyText: 'Hello from another child.',
      locale: 'en',
      createdAt: createdAt,
      updatedAt: updatedAt,
      contentVersion: 7,
    ));
    await box.put('broken-json', '{not valid json');
    await box.close();
    await Hive.close();

    Hive.init(directory.path);
    box = await Hive.openBox('creative_artifacts_test');
    final reopened = HiveCreativeArtifactStore(box);

    final loaded = reopened.load(
      childProfileId: 'child-a',
      artifactId: 'artifact-1',
    )!;
    expect(loaded.storyText, 'MI mở cửa lần nữa 😊.');
    expect(loaded.revision, 2);
    expect(loaded.schemaVersion, 1);
    expect(loaded.contentVersion, 7);
    expect(loaded.assetReferences, ['asset://scene-door']);
    expect(loaded.storyStarterId, 'starter-1');
    expect(reopened.listForChild('child-a'), hasLength(1));
    expect(reopened.listForChild('child-b'), hasLength(1));
  });
}
