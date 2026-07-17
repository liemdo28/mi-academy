import 'package:mi_game_core/mi_game_core.dart';

/// In-memory fake implementation of game services for tests.
///
/// Records all calls so tests can assert on them.
class FakeGameServices {
  final Map<String, Map<String, dynamic>> savedSnapshots = {};
  final List<({String event, Map<String, dynamic> data})> loggedEvents = [];
  final List<({String audioRef, double? volume})> playedAudio = [];
  int stopAudioCallCount = 0;

  MiGameServices build() {
    return MiGameServices(
      saveSnapshot: (key, data) async {
        savedSnapshots[key] = data;
      },
      loadSnapshot: (key) async => savedSnapshots[key],
      logEvent: (event, data) async {
        loggedEvents.add((event: event, data: data));
      },
      playAudio: (audioRef, {volume}) async {
        playedAudio.add((audioRef: audioRef, volume: volume));
      },
      stopAudio: () async {
        stopAudioCallCount++;
      },
    );
  }

  /// Whether an event with the given name was logged.
  bool hasLoggedEvent(String eventName) {
    return loggedEvents.any((e) => e.event == eventName);
  }

  /// Whether audio with the given ref was played.
  bool hasPlayedAudio(String audioRef) {
    return playedAudio.any((a) => a.audioRef == audioRef);
  }

  void reset() {
    savedSnapshots.clear();
    loggedEvents.clear();
    playedAudio.clear();
    stopAudioCallCount = 0;
  }
}
