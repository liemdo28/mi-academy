import 'dart:convert';
import 'dart:io';

const _logoFiles = {
  'primary': 'assets/branding/logo/mi_academy_primary.svg',
  'stacked': 'assets/branding/logo/mi_academy_stacked.svg',
  'symbol': 'assets/branding/logo/mi_academy_symbol.svg',
  'monochrome': 'assets/branding/logo/mi_academy_monochrome.svg',
};

const _mascotFiles = {
  'welcome': 'assets/branding/mascot/welcome.svg',
  'success': 'assets/branding/mascot/success.svg',
  'thinking': 'assets/branding/mascot/thinking.svg',
  'confused': 'assets/branding/mascot/confused.svg',
  'excited': 'assets/branding/mascot/excited.svg',
  'encouraging': 'assets/branding/mascot/encouraging.svg',
  'tryAgain': 'assets/branding/mascot/try_again.svg',
  'celebration': 'assets/branding/mascot/celebration.svg',
  'apology': 'assets/branding/mascot/apology.svg',
  'love': 'assets/branding/mascot/love.svg',
  'sleeping': 'assets/branding/mascot/sleeping.svg',
  'surprised': 'assets/branding/mascot/surprised.svg',
};

const _brandIconFiles = {
  'alphabet': 'assets/branding/icons/learning/alphabet.svg',
  'numbers': 'assets/branding/icons/learning/numbers.svg',
  'logic': 'assets/branding/icons/learning/logic.svg',
  'memory': 'assets/branding/icons/learning/memory.svg',
  'writing': 'assets/branding/icons/learning/writing.svg',
  'listening': 'assets/branding/icons/learning/listening.svg',
  'rewardStar': 'assets/branding/icons/rewards/reward_star.svg',
  'achievement': 'assets/branding/icons/rewards/achievement.svg',
  'progress': 'assets/branding/icons/rewards/progress.svg',
  'profile': 'assets/branding/icons/profile/profile.svg',
  'parent': 'assets/branding/icons/profile/parent.svg',
  'report': 'assets/branding/icons/profile/report.svg',
  'world': 'assets/branding/icons/navigation/world.svg',
  'exploration': 'assets/branding/icons/navigation/exploration.svg',
  'garden': 'assets/branding/icons/navigation/garden.svg',
  'offline': 'assets/branding/icons/navigation/offline.svg',
};

const _appIconSources = {
  'androidForeground': 'assets/branding/app_icon/android/foreground.svg',
  'androidBackground': 'assets/branding/app_icon/android/background.svg',
  'androidMonochrome': 'assets/branding/app_icon/android/monochrome.svg',
  'playStore512': 'assets/branding/app_icon/android/play_store_512.png',
  'iosMaster1024': 'assets/branding/app_icon/ios/app_icon_master_1024.png',
};

const _androidRequiredConfig = {
  'manifest': 'apps/mobile/android/app/src/main/AndroidManifest.xml',
  'adaptive':
      'apps/mobile/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
  'roundAdaptive':
      'apps/mobile/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml',
  'foregroundPlaceholder':
      'apps/mobile/android/app/src/main/res/drawable/ic_launcher_foreground_placeholder.xml',
  'monochromePlaceholder':
      'apps/mobile/android/app/src/main/res/drawable/ic_launcher_monochrome_placeholder.xml',
  'backgroundColor': 'apps/mobile/android/app/src/main/res/values/colors.xml',
};

const _iosCatalog =
    'apps/mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json';

void main(List<String> args) {
  final strict = args.contains('--strict');
  final result = _BrandAssetValidationResult();

  _validateSvgGroup('logo', _logoFiles, result);
  _validateSvgGroup('mascot', _mascotFiles, result);
  _validateSvgGroup('brandIcon', _brandIconFiles, result);
  _validateAppIconSources(result);
  _validateAndroidConfig(result);
  _validateIosCatalog(result);
  _validateNoOrphanProductionAssets(result);

  stdout.writeln(result.toReport());
  if (strict && result.hasProductionBlockers) {
    exitCode = 1;
  }
}

void _validateSvgGroup(
  String group,
  Map<String, String> expected,
  _BrandAssetValidationResult result,
) {
  for (final entry in expected.entries) {
    final file = File(entry.value);
    if (!file.existsSync()) {
      result.missing.add('$group.${entry.key}: ${entry.value}');
      continue;
    }
    final runtimePath = 'packages/design_system/${entry.value}';
    if (!File(runtimePath).existsSync()) {
      result.invalid.add(
        '$group.${entry.key}: missing runtime copy $runtimePath',
      );
    }
    _validateSvg(file, '$group.${entry.key}', result);
  }
}

void _validateSvg(File file, String id, _BrandAssetValidationResult result) {
  final source = file.readAsStringSync();
  if (!source.trimLeft().startsWith('<svg') &&
      !source.trimLeft().startsWith('<?xml')) {
    result.invalid.add('$id: not an SVG/XML document');
  }
  if (!RegExp(
    r'<svg\b[^>]*\bviewBox\s*=',
    caseSensitive: false,
  ).hasMatch(source)) {
    result.invalid.add('$id: missing viewBox');
  }
  if (RegExp(
    r'<(script|foreignObject)\b',
    caseSensitive: false,
  ).hasMatch(source)) {
    result.invalid.add('$id: contains script or foreignObject');
  }
  if (RegExp(
    r'<image\b|data:image|\.png|\.jpg|\.jpeg|\.webp',
    caseSensitive: false,
  ).hasMatch(source)) {
    result.invalid.add('$id: embeds or links raster imagery');
  }
  if (RegExp(
    r'https?://|file://|C:\\|/Users/|/home/',
    caseSensitive: false,
  ).hasMatch(source)) {
    result.invalid.add('$id: contains external or local-resource reference');
  }
  if (RegExp(
    r'font-family\s*:|font-family=',
    caseSensitive: false,
  ).hasMatch(source)) {
    result.invalid.add('$id: contains font-family dependency');
  }
  if (RegExp(r'<(filter|mask)\b', caseSensitive: false).hasMatch(source)) {
    result.warnings.add(
      '$id: contains filter or mask; verify Flutter rendering',
    );
  }
  final pathCount = RegExp(
    r'<path\b',
    caseSensitive: false,
  ).allMatches(source).length;
  if (pathCount > 250) {
    result.warnings.add('$id: high path count ($pathCount)');
  }
}

void _validateAppIconSources(_BrandAssetValidationResult result) {
  for (final entry in _appIconSources.entries) {
    final file = File(entry.value);
    if (!file.existsSync()) {
      result.missing.add('appIcon.${entry.key}: ${entry.value}');
      continue;
    }
    if (entry.value.endsWith('.svg')) {
      _validateSvg(file, 'appIcon.${entry.key}', result);
    } else if (file.lengthSync() == 0) {
      result.invalid.add('appIcon.${entry.key}: empty raster file');
    }
  }
}

void _validateAndroidConfig(_BrandAssetValidationResult result) {
  for (final entry in _androidRequiredConfig.entries) {
    if (!File(entry.value).existsSync()) {
      result.invalid.add('androidConfig.${entry.key}: missing ${entry.value}');
    }
  }
  final manifest = File(_androidRequiredConfig['manifest']!);
  if (manifest.existsSync()) {
    final source = manifest.readAsStringSync();
    if (!source.contains('android:icon="@mipmap/ic_launcher"')) {
      result.invalid.add(
        'androidConfig.manifest: missing launcher icon reference',
      );
    }
    if (!source.contains('android:roundIcon="@mipmap/ic_launcher_round"')) {
      result.invalid.add(
        'androidConfig.manifest: missing round icon reference',
      );
    }
  }
  for (final key in const ['adaptive', 'roundAdaptive']) {
    final adaptive = File(_androidRequiredConfig[key]!);
    if (adaptive.existsSync()) {
      final source = adaptive.readAsStringSync();
      if (source.contains('_placeholder')) {
        result.placeholders.add(
          'androidConfig.$key: still references placeholder layers',
        );
      }
      if (!source.contains('<monochrome')) {
        result.invalid.add('androidConfig.$key: missing monochrome layer');
      }
    }
  }
}

void _validateIosCatalog(_BrandAssetValidationResult result) {
  final file = File(_iosCatalog);
  if (!file.existsSync()) {
    result.invalid.add('iosCatalog: missing $_iosCatalog');
    return;
  }
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final images = (json['images'] as List<dynamic>? ?? const [])
      .cast<Map<String, dynamic>>();
  final slots = <String>{};
  for (final image in images) {
    final filename = image['filename'] as String?;
    if (filename == null || filename.isEmpty) {
      result.invalid.add('iosCatalog: image entry missing filename');
      continue;
    }
    final slot = '${image['idiom']}|${image['size']}|${image['scale']}';
    if (!slots.add(slot)) {
      result.warnings.add('iosCatalog: duplicate slot $slot');
    }
    final iconFile = File(
      'apps/mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/$filename',
    );
    if (!iconFile.existsSync()) {
      result.invalid.add('iosCatalog: missing raster $filename');
    }
  }
  if (!images.any(
    (image) =>
        image['idiom'] == 'ios-marketing' && image['size'] == '1024x1024',
  )) {
    result.invalid.add('iosCatalog: missing 1024x1024 marketing entry');
  }
}

void _validateNoOrphanProductionAssets(_BrandAssetValidationResult result) {
  final allowed = {
    ..._logoFiles.values,
    ..._mascotFiles.values,
    ..._brandIconFiles.values,
    ..._appIconSources.values,
  };
  final root = Directory('assets/branding');
  if (!root.existsSync()) return;
  final productionFiles = root
      .listSync(recursive: true)
      .whereType<File>()
      .where(
        (file) =>
            !file.path.contains(
              '${Platform.pathSeparator}placeholders${Platform.pathSeparator}',
            ) &&
            !file.path.endsWith('.gitkeep') &&
            !file.path.endsWith('README.md'),
      )
      .map((file) => file.path.replaceAll(r'\', '/'))
      .toList();
  for (final path in productionFiles) {
    if (!allowed.contains(path)) {
      result.warnings.add('orphanProductionAsset: $path is not mapped');
    }
  }
}

class _BrandAssetValidationResult {
  final missing = <String>[];
  final invalid = <String>[];
  final warnings = <String>[];
  final placeholders = <String>[];

  bool get hasProductionBlockers =>
      missing.isNotEmpty || invalid.isNotEmpty || placeholders.isNotEmpty;

  String toReport() {
    final buffer = StringBuffer()
      ..writeln('Mi Academy production brand asset validation')
      ..writeln('Status: ${hasProductionBlockers ? 'NOT READY' : 'READY'}')
      ..writeln();
    _writeSection(buffer, 'Missing required production assets', missing);
    _writeSection(buffer, 'Invalid supplied assets/config', invalid);
    _writeSection(buffer, 'Placeholder references', placeholders);
    _writeSection(buffer, 'Warnings', warnings);
    return buffer.toString();
  }

  void _writeSection(StringBuffer buffer, String title, List<String> items) {
    buffer.writeln('$title (${items.length})');
    if (items.isEmpty) {
      buffer.writeln('- none');
    } else {
      for (final item in items) {
        buffer.writeln('- $item');
      }
    }
    buffer.writeln();
  }
}
