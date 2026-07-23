import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('audio manifest points to real family-test WAV assets', () {
    final manifestFile = File('assets/audio/audio_manifest.json');
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final assets = (manifest['assets'] as List).cast<Map<String, dynamic>>();

    expect(assets, isNotEmpty);
    for (final asset in assets) {
      expect(asset['placeholder'], isFalse,
          reason: asset['assetKey'] as String);
      expect(asset['reviewStatus'], 'family_test_ready');

      final filePath = (asset['file'] as String).replaceFirst('assets/', '');
      final audioFile = File('assets/$filePath');
      expect(audioFile.existsSync(), isTrue, reason: filePath);
      expect(audioFile.lengthSync(), greaterThan(44), reason: filePath);

      final header = audioFile.openSync();
      try {
        final bytes = header.readSync(12);
        expect(ascii.decode(bytes.take(4).toList()), 'RIFF', reason: filePath);
        expect(ascii.decode(bytes.skip(8).take(4).toList()), 'WAVE',
            reason: filePath);
      } finally {
        header.closeSync();
      }
    }
  });
}
