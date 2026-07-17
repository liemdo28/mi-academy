import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_audio/mi_game_audio.dart';

class FakeAudioBackend implements AudioBackend {
  final played = <({String assetPath, double volume, double rate})>[];
  final volumes = <String, double>{};
  var stopAllCount = 0;

  @override
  Future<void> play(String assetPath, {required double volume, double rate = 1.0}) async {
    played.add((assetPath: assetPath, volume: volume, rate: rate));
  }

  @override
  Future<void> setVolume(String playerId, double volume) async {
    volumes[playerId] = volume;
  }

  @override
  Future<void> stopAll() async {
    stopAllCount++;
  }
}

void main() {
  group('AudioManager', () {
    test('plays effects through backend', () async {
      final backend = FakeAudioBackend();
      final manager = AudioManager(backend: backend);

      await manager.playEffect('audio/correct.wav');

      expect(backend.played.single.assetPath, 'audio/correct.wav');
      expect(backend.played.single.volume, 0.8);
      expect(backend.played.single.rate, 1.0);
    });

    test('plays music at music volume', () async {
      final backend = FakeAudioBackend();
      final manager = AudioManager(backend: backend);

      await manager.playMusic('audio/garden_theme.wav');

      expect(backend.played.single.assetPath, 'audio/garden_theme.wav');
      expect(backend.played.single.volume, 0.5);
      expect(backend.played.single.rate, 1.0);
    });

    test('clamps configured volumes before playback', () async {
      final backend = FakeAudioBackend();
      final manager = AudioManager(
        backend: backend,
        settings: VolumeSettings(voice: 1.7, music: -0.2, effects: 1.4),
      );

      await manager.playVoice('audio/letter_a.wav');
      await manager.playMusic('audio/theme.wav');
      await manager.playEffect('audio/correct.wav');

      expect(backend.played[0].volume, 1.0);
      expect(backend.played[1].volume, 0.0);
      expect(backend.played[2].volume, 1.0);
    });

    test('master mute silences every volume group', () async {
      final backend = FakeAudioBackend();
      final manager = AudioManager(
        backend: backend,
        settings: VolumeSettings(masterMuted: true),
      );

      await manager.playVoice('audio/letter_a.wav');
      await manager.playMusic('audio/theme.wav');
      await manager.playEffect('audio/correct.wav');

      expect(backend.played.map((p) => p.volume), everyElement(0.0));
    });

    test('updateSettings affects later playback', () async {
      final backend = FakeAudioBackend();
      final manager = AudioManager(backend: backend);

      manager.updateSettings(VolumeSettings(effects: 0.25));
      await manager.playEffect('audio/correct.wav');

      expect(manager.settings.effects, 0.25);
      expect(backend.played.single.volume, 0.25);
    });

    test('ducks music when voice plays and restores it', () async {
      final backend = FakeAudioBackend();
      final manager = AudioManager(backend: backend);

      await manager.playVoice('audio/letter_a.wav');
      expect(manager.isDucked, isTrue);
      expect(backend.volumes['music'], 0.15);

      await manager.unduckMusic();
      expect(manager.isDucked, isFalse);
      expect(backend.volumes['music'], 0.5);
    });

    test('does not duck music more than once during continuous narration',
        () async {
      final backend = FakeAudioBackend();
      final manager = AudioManager(backend: backend);

      await manager.playVoice('audio/letter_a.wav');
      await manager.playVoice('audio/letter_b.wav');

      expect(backend.volumes.length, 1);
      expect(backend.volumes['music'], 0.15);
      expect(backend.played.length, 2);
    });

    test('plays slow voice at pronunciation-help rate', () async {
      final backend = FakeAudioBackend();
      final manager = AudioManager(backend: backend);

      await manager.playVoiceSlow('audio/word_meo.wav');

      expect(backend.played.single.assetPath, 'audio/word_meo.wav');
      expect(backend.played.single.rate, 0.6);
    });

    test('stopAll delegates to backend and clears ducked state', () async {
      final backend = FakeAudioBackend();
      final manager = AudioManager(backend: backend);

      await manager.playVoice('audio/letter_a.wav');
      await manager.stopAll();

      expect(backend.stopAllCount, 1);
      expect(manager.isDucked, isFalse);
    });

    test('tracks preload cache', () async {
      final manager = AudioManager(backend: FakeAudioBackend());

      await manager.preload('audio/letter_a.wav');

      expect(manager.isCached('audio/letter_a.wav'), isTrue);
    });
  });

  group('VolumeSettings', () {
    test('copyWith preserves unchanged groups', () {
      final settings = VolumeSettings(voice: 0.9, music: 0.4, effects: 0.7);

      final updated = settings.copyWith(music: 0.1, masterMuted: true);

      expect(updated.voice, 0.9);
      expect(updated.music, 0.1);
      expect(updated.effects, 0.7);
      expect(updated.masterMuted, isTrue);
    });
  });

  group('AudioPrefs', () {
    test('serializes parent audio preferences to JSON', () {
      const prefs = AudioPrefs(
        voice: 0.6,
        music: 0.2,
        effects: 0.9,
        masterMuted: true,
        speechEnabled: false,
      );

      expect(prefs.toJson(), {
        'voice': 0.6,
        'music': 0.2,
        'effects': 0.9,
        'master_muted': true,
        'speech_enabled': false,
      });
    });

    test('loads defaults for missing JSON fields', () {
      final prefs = AudioPrefs.fromJson(const {});

      expect(prefs, AudioPrefs.defaults);
    });

    test('converts to VolumeSettings without losing mute state', () {
      const prefs = AudioPrefs(effects: 0.3, masterMuted: true);

      final settings = prefs.toVolumeSettings();

      expect(settings.effects, 0.3);
      expect(settings.masterMuted, isTrue);
      expect(settings.effectiveVolume(VolumeGroup.effects), 0.0);
    });
  });

  group('AudioMetadata', () {
    test('round-trips reviewed metadata with recording date', () {
      final metadata = AudioMetadata(
        assetKey: 'word_meo',
        language: 'Vietnamese',
        locale: 'vi',
        transcript: 'meo',
        speaker: 'approved-child-safe-voice',
        speed: 0.95,
        normalizedVolume: 0.88,
        recordingDate: DateTime.utc(2026, 7, 17),
        reviewStatus: AudioReviewStatus.approved,
      );

      final restored = AudioMetadata.fromJson(metadata.toJson());

      expect(restored, metadata);
      expect(restored.isApproved, isTrue);
    });

    test('uses pending review status for unknown status values', () {
      final metadata = AudioMetadata.fromJson({
        'assetKey': 'letter_a',
        'language': 'English',
        'locale': 'en',
        'transcript': 'A',
        'reviewStatus': 'needs-review',
      });

      expect(metadata.reviewStatus, AudioReviewStatus.pending);
      expect(metadata.isApproved, isFalse);
    });
  });
}
