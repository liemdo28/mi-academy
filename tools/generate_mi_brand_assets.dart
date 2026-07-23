import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const _orange = '#FF8A00';
const _green = '#4CAF50';
const _blue = '#4A90E2';
const _purple = '#8E6BFF';
const _yellow = '#FFD23F';
const _navy = '#1E2A44';
const _cloud = '#F4F6FA';
const _skin = '#FFD0A6';
const _hair = '#2F1B14';

void main() {
  _writeLogos();
  _writeMascots();
  _writeBrandIcons();
  _writeAppIconSources();
  _writeAndroidLauncherVectors();
  _copyRuntimeSvgs();
}

void _writeLogos() {
  _write(
    'assets/branding/logo/mi_academy_primary.svg',
    _logoSvg(width: 720, height: 320, stacked: false, monochrome: false),
  );
  _write(
    'assets/branding/logo/mi_academy_stacked.svg',
    _logoSvg(width: 420, height: 420, stacked: true, monochrome: false),
  );
  _write(
    'assets/branding/logo/mi_academy_symbol.svg',
    _symbolSvg(monochrome: false),
  );
  _write(
    'assets/branding/logo/mi_academy_monochrome.svg',
    _logoSvg(width: 720, height: 320, stacked: false, monochrome: true),
  );
}

String _logoSvg({
  required int width,
  required int height,
  required bool stacked,
  required bool monochrome,
}) {
  final o = monochrome ? _navy : _orange;
  final g = monochrome ? _navy : _green;
  final y = monochrome ? _navy : _yellow;
  final n = _navy;
  final mascot = _miniMascot(x: stacked ? 80 : 76, y: 28, scale: 0.55);
  final markX = stacked ? 92.0 : 172.0;
  final academyY = stacked ? 294.0 : 244.0;
  final symbol =
      '''
    <g transform="translate($markX ${stacked ? 70 : 62})">
      <path d="M0 150V18c0-13 10-22 23-18 9 2 16 9 21 18l42 76 42-76c5-9 12-16 22-18 13-3 23 5 23 18v132c0 13-10 23-23 23s-23-10-23-23V82l-25 44c-8 14-24 14-32 0L46 82v68c0 13-10 23-23 23S0 163 0 150Z" fill="$o"/>
      <rect x="204" y="48" width="48" height="125" rx="24" fill="$g"/>
      <circle cx="228" cy="19" r="23" fill="$g"/>
      ${_starPath(cx: 228, cy: -28, r: 28, fill: y, stroke: '#F6B100')}
    </g>
  ''';
  return _svg(width, height, '''
    <g filter="none">
      ${monochrome ? '' : mascot}
      $symbol
      ${_wordAcademy(x: stacked ? 56 : 192, y: academyY, scale: stacked ? 0.82 : 1, fill: n)}
      ${stacked ? '' : _tagline(x: 198, y: 298)}
    </g>
  ''');
}

String _symbolSvg({required bool monochrome}) {
  final o = monochrome ? _navy : _orange;
  final g = monochrome ? _navy : _green;
  final y = monochrome ? _navy : _yellow;
  return _svg(360, 360, '''
    <rect x="18" y="18" width="324" height="324" rx="74" fill="$_cloud" stroke="#E1E6F0" stroke-width="6"/>
    ${_miniMascot(x: 54, y: 42, scale: 0.52)}
    <g transform="translate(66 114)">
      <path d="M0 150V18c0-13 10-22 23-18 9 2 16 9 21 18l42 76 42-76c5-9 12-16 22-18 13-3 23 5 23 18v132c0 13-10 23-23 23s-23-10-23-23V82l-25 44c-8 14-24 14-32 0L46 82v68c0 13-10 23-23 23S0 163 0 150Z" fill="$o"/>
      <rect x="204" y="48" width="48" height="125" rx="24" fill="$g"/>
      <circle cx="228" cy="19" r="23" fill="$g"/>
      ${_starPath(cx: 228, cy: -28, r: 28, fill: y, stroke: '#F6B100')}
    </g>
    ${_wordAcademy(x: 62, y: 306, scale: 0.64, fill: _navy)}
  ''');
}

String _wordAcademy({
  required double x,
  required double y,
  required double scale,
  required String fill,
}) {
  // Letterforms are simple outlined vector blocks to avoid font dependencies.
  const letters = [
    'M12 70 34 6h28l22 64H60l-3-11H38l-4 11H12Zm32-31h8l-4-14-4 14Z',
    'M112 38c0-20 16-36 38-36 15 0 27 7 33 18l-19 11c-3-5-8-8-14-8-10 0-17 7-17 16 0 10 7 17 17 17 7 0 12-3 15-9l19 11c-7 12-19 19-35 19-22 0-38-16-38-39Z',
    'M204 70 226 6h28l22 64h-24l-3-11h-19l-4 11h-22Zm32-31h8l-4-14-4 14Z',
    'M298 6h30c23 0 39 13 39 32s-16 32-39 32h-30V6Zm23 20v24h7c10 0 17-4 17-12s-7-12-17-12h-7Z',
    'M390 6h55v19h-33v5h29v17h-29v5h34v18h-56V6Z',
    'M469 70V6h24l18 30 18-30h24v64h-22V40l-13 21h-14l-13-21v30h-22Z',
    'M578 70V45L553 6h26l11 20 11-20h26l-26 39v25h-23Z',
  ];
  final body = StringBuffer();
  for (final path in letters) {
    body.writeln('<path d="$path" fill="$fill"/>');
  }
  return '<g transform="translate($x $y) scale($scale)">${body.toString()}</g>';
}

String _tagline({required double x, required double y}) =>
    '''
  <g transform="translate($x $y)">
    <path d="M0 0h38c12 0 20 8 20 19s-8 19-20 19H18v22H0V0Zm18 15v8h17c3 0 5-2 5-4s-2-4-5-4H18Z" fill="$_orange"/>
    <circle cx="86" cy="31" r="5" fill="$_navy"/>
    <path d="M116 0h18v44h35v16h-53V0Zm76 60 22-60h24l22 60h-20l-3-10h-22l-3 10h-20Zm28-25h12l-6-18-6 18Z" fill="$_green"/>
    <circle cx="288" cy="31" r="5" fill="$_navy"/>
    <path d="M318 30c0-18 14-32 34-32 13 0 24 6 29 15l-15 9c-3-5-8-8-14-8-10 0-17 7-17 16s7 16 17 16c5 0 10-2 13-5v-3h-18V24h35v25c-7 8-18 13-31 13-20 0-33-14-33-32Zm90 30V0h31c14 0 23 8 23 20 0 8-4 14-11 18l15 22h-21l-12-18h-7v18h-18Zm18-33h12c4 0 7-2 7-6s-3-6-7-6h-12v12Zm61 3c0-18 14-32 34-32s34 14 34 32-14 32-34 32-34-14-34-32Zm18 0c0 9 7 16 16 16s16-7 16-16-7-16-16-16-16 7-16 16Z" fill="$_blue"/>
  </g>
''';

void _writeMascots() {
  final poses = {
    'welcome': _MascotPose(wave: true, mouth: 'smile'),
    'success': _MascotPose(thumb: true, mouth: 'smile', star: true),
    'thinking': _MascotPose(handToChin: true, mouth: 'small', mark: '?'),
    'confused': _MascotPose(handToChin: true, mouth: 'small', mark: '??'),
    'excited': _MascotPose(wave: true, mouth: 'open', star: true),
    'encouraging': _MascotPose(ok: true, mouth: 'smile'),
    'try_again': _MascotPose(handToChin: true, mouth: 'soft'),
    'celebration': _MascotPose(armsUp: true, mouth: 'open', star: true),
    'apology': _MascotPose(handsTogether: true, mouth: 'soft'),
    'love': _MascotPose(heart: true, mouth: 'smile'),
    'sleeping': _MascotPose(eyesClosed: true, mouth: 'soft', mark: 'z'),
    'surprised': _MascotPose(armsUp: true, mouth: 'o', mark: '!'),
  };
  for (final entry in poses.entries) {
    _write('assets/branding/mascot/${entry.key}.svg', _mascotSvg(entry.value));
  }
}

String _mascotSvg(_MascotPose pose) => _svg(260, 260, '''
  <path d="M40 216c24 18 151 20 179 0 18-13 18-55 0-81-22-31-52-43-89-43s-68 12-90 43c-18 26-18 68 0 81Z" fill="#FFFFFF"/>
  ${pose.star ? _starPath(cx: 216, cy: 44, r: 20, fill: _yellow, stroke: '#F6B100') : ''}
  ${pose.heart ? '<path d="M207 45c10-18 37-6 28 15-6 13-19 23-28 31-9-8-22-18-28-31-9-21 18-33 28-15Z" fill="#FF5DA2" stroke="#D83C82" stroke-width="4"/>' : ''}
  ${pose.mark == '?' ? _questionMark(207, 48) : ''}
  ${pose.mark == '??' ? _questionMark(198, 44) + _questionMark(226, 36, scale: 0.75) : ''}
  ${pose.mark == '!' ? '<path d="M218 28h18l-4 48h-10l-4-48Zm2 62a9 9 0 1 0 18 0 9 9 0 0 0-18 0Z" fill="$_blue"/>' : ''}
  ${pose.mark == 'z' ? '<path d="M200 36h36l-20 26h20v13h-40l21-27h-17V36Z" fill="$_blue"/>' : ''}
  <g>
    ${_bodyAndArms(pose)}
    ${_head(pose)}
  </g>
''');

String _bodyAndArms(_MascotPose pose) {
  final leftArm = pose.armsUp || pose.wave
      ? '<path d="M73 134c-29-18-34-43-23-52 12-9 24 11 35 29" fill="none" stroke="$_skin" stroke-width="22" stroke-linecap="round"/>'
      : pose.thumb
      ? '<path d="M73 144c-32 0-43-21-34-34 9-13 25 2 39 15" fill="none" stroke="$_skin" stroke-width="22" stroke-linecap="round"/>'
      : '<path d="M77 140c-30 4-42 22-35 35 8 13 26-4 43-19" fill="none" stroke="$_skin" stroke-width="22" stroke-linecap="round"/>';
  final rightArm = pose.armsUp
      ? '<path d="M184 132c30-16 37-41 27-51-11-10-25 9-37 26" fill="none" stroke="$_skin" stroke-width="22" stroke-linecap="round"/>'
      : pose.handToChin
      ? '<path d="M178 145c24 18 7 40-15 29" fill="none" stroke="$_skin" stroke-width="22" stroke-linecap="round"/>'
      : pose.handsTogether
      ? '<path d="M178 152c-12 22-34 23-48 8" fill="none" stroke="$_skin" stroke-width="22" stroke-linecap="round"/>'
      : '<path d="M180 143c31 2 42 22 34 35-8 13-26-5-42-20" fill="none" stroke="$_skin" stroke-width="22" stroke-linecap="round"/>';
  final hand = pose.ok
      ? '<circle cx="213" cy="174" r="14" fill="none" stroke="$_skin" stroke-width="8"/><path d="M223 164l20-16" stroke="$_skin" stroke-width="8" stroke-linecap="round"/>'
      : '';
  return '''
    $leftArm
    $rightArm
    <path d="M73 142c0-38 24-63 57-63s57 25 57 63v70H73v-70Z" fill="$_orange" stroke="#E46F00" stroke-width="5"/>
    <path d="M108 84h44l-22 36-22-36Z" fill="$_blue"/>
    $hand
  ''';
}

String _head(_MascotPose pose) {
  final eyes = pose.eyesClosed
      ? '<path d="M99 122c10 8 20 8 30 0M151 122c10 8 20 8 30 0" fill="none" stroke="$_hair" stroke-width="7" stroke-linecap="round"/>'
      : '<circle cx="112" cy="120" r="12" fill="$_hair"/><circle cx="164" cy="120" r="12" fill="$_hair"/><circle cx="116" cy="115" r="4" fill="#fff"/><circle cx="168" cy="115" r="4" fill="#fff"/>';
  final mouth = switch (pose.mouth) {
    'open' =>
      '<path d="M123 147c10 20 38 20 49 0 4-8-2-16-10-13-9 4-20 4-29 0-8-3-14 5-10 13Z" fill="$_hair"/><path d="M136 160c8 5 18 5 26 0" stroke="#FF8FA8" stroke-width="5" stroke-linecap="round"/>',
    'o' => '<ellipse cx="145" cy="151" rx="12" ry="16" fill="$_hair"/>',
    'small' =>
      '<path d="M131 154c9-6 21-6 30 0" fill="none" stroke="$_hair" stroke-width="6" stroke-linecap="round"/>',
    'soft' =>
      '<path d="M127 149c11 10 26 10 37 0" fill="none" stroke="$_hair" stroke-width="6" stroke-linecap="round"/>',
    _ =>
      '<path d="M121 145c12 18 39 18 51 0" fill="none" stroke="$_hair" stroke-width="8" stroke-linecap="round"/>',
  };
  return '''
    <circle cx="88" cy="123" r="15" fill="$_skin" stroke="#F1A174" stroke-width="4"/>
    <circle cx="188" cy="123" r="15" fill="$_skin" stroke="#F1A174" stroke-width="4"/>
    <path d="M84 92c8-39 38-59 76-51 31 6 46 31 39 63-5 28-28 58-62 58-35 0-59-29-53-70Z" fill="$_skin" stroke="#F1A174" stroke-width="4"/>
    <path d="M84 93c-5-29 16-57 49-63 39-8 70 15 71 48-29-15-61-13-97 4 8 8 15 13 24 16-20 3-35 1-47-5Z" fill="$_hair"/>
    <path d="M91 98c-8-15 0-31 13-37 4 18 20 26 43 25-20 13-39 17-56 12Z" fill="$_hair"/>
    <path d="M103 104c11-8 23-8 34-1M151 103c11-7 23-6 33 2" fill="none" stroke="$_hair" stroke-width="6" stroke-linecap="round"/>
    $eyes
    <circle cx="102" cy="141" r="7" fill="#FF9C7B" opacity=".65"/>
    <circle cx="178" cy="141" r="7" fill="#FF9C7B" opacity=".65"/>
    $mouth
  ''';
}

String _miniMascot({
  required double x,
  required double y,
  required double scale,
}) =>
    '<g transform="translate($x $y) scale($scale)">${_bodyAndArms(_MascotPose(wave: true, mouth: 'open'))}${_head(_MascotPose(wave: true, mouth: 'open'))}</g>';

void _writeBrandIcons() {
  final icons = <String, String>{
    'assets/branding/icons/learning/alphabet.svg': _iconSvg(
      _orange,
      _abcIcon(),
    ),
    'assets/branding/icons/learning/numbers.svg': _iconSvg(
      _green,
      _numbersIcon(),
    ),
    'assets/branding/icons/learning/logic.svg': _iconSvg(
      _purple,
      _puzzleIcon(),
    ),
    'assets/branding/icons/learning/memory.svg': _iconSvg(_blue, _memoryIcon()),
    'assets/branding/icons/learning/writing.svg': _iconSvg(
      _orange,
      _pencilIcon(),
    ),
    'assets/branding/icons/learning/listening.svg': _iconSvg(
      _blue,
      _listeningIcon(),
    ),
    'assets/branding/icons/rewards/reward_star.svg': _iconSvg(
      _yellow,
      _starPath(cx: 64, cy: 62, r: 38, fill: _yellow, stroke: '#F6B100'),
    ),
    'assets/branding/icons/rewards/achievement.svg': _iconSvg(
      _yellow,
      _trophyIcon(),
    ),
    'assets/branding/icons/rewards/progress.svg': _iconSvg(
      _green,
      _progressIcon(),
    ),
    'assets/branding/icons/profile/profile.svg': _iconSvg(
      _blue,
      _profileIcon(child: true),
    ),
    'assets/branding/icons/profile/parent.svg': _iconSvg(
      _navy,
      _profileIcon(child: false),
    ),
    'assets/branding/icons/profile/report.svg': _iconSvg(
      _purple,
      _reportIcon(),
    ),
    'assets/branding/icons/navigation/world.svg': _iconSvg(
      _green,
      _worldIcon(),
    ),
    'assets/branding/icons/navigation/exploration.svg': _iconSvg(
      _orange,
      _compassIcon(),
    ),
    'assets/branding/icons/navigation/garden.svg': _iconSvg(
      _green,
      _gardenIcon(),
    ),
    'assets/branding/icons/navigation/offline.svg': _iconSvg(
      _blue,
      _offlineIcon(),
    ),
  };
  icons.forEach(_write);
}

String _iconSvg(String accent, String inner) => _svg(128, 128, '''
  <path d="M20 111c21 15 68 15 88 0 16-12 18-78 0-94-19-17-68-17-88 0-18 16-16 82 0 94Z" fill="#FFFFFF"/>
  <rect x="17" y="17" width="94" height="94" rx="25" fill="$accent" opacity=".18"/>
  $inner
''');

String _abcIcon() =>
    '''
  <rect x="28" y="34" width="33" height="33" rx="9" fill="$_orange" stroke="#E46F00" stroke-width="4"/>
  <rect x="55" y="55" width="33" height="33" rx="9" fill="$_green" stroke="#328C35" stroke-width="4"/>
  <rect x="35" y="72" width="33" height="33" rx="9" fill="$_blue" stroke="#2B6EB4" stroke-width="4"/>
  <path d="M39 59l7-18 7 18M42 53h8M66 80V63h10c8 0 8 17 0 17H66Zm0-9h11" stroke="#fff" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
''';

String _numbersIcon() =>
    '''
  <path d="M35 43h14v43M76 47c18 0 18 18 3 29l-18 14h35" fill="none" stroke="$_green" stroke-width="12" stroke-linecap="round" stroke-linejoin="round"/>
  <circle cx="96" cy="38" r="7" fill="$_yellow"/>
''';

String _puzzleIcon() =>
    '''
  <path d="M39 41h22c-2-14 18-14 16 0h15v20c14-2 14 18 0 16v20H72c2-14-18-14-16 0H39V78c-14 2-14-18 0-16V41Z" fill="$_purple" stroke="#6547D8" stroke-width="5" stroke-linejoin="round"/>
''';

String _memoryIcon() =>
    '''
  <rect x="31" y="33" width="28" height="38" rx="7" fill="$_blue" stroke="#2B6EB4" stroke-width="5"/>
  <rect x="69" y="33" width="28" height="38" rx="7" fill="$_purple" stroke="#6547D8" stroke-width="5"/>
  <rect x="50" y="70" width="28" height="26" rx="7" fill="$_yellow" stroke="#F6B100" stroke-width="5"/>
''';

String _pencilIcon() =>
    '''
  <path d="M34 91l9-27 36-36c6-6 19 7 13 13L56 77 34 91Z" fill="$_yellow" stroke="#D88C00" stroke-width="5" stroke-linejoin="round"/>
  <path d="M75 32l21 21" stroke="$_orange" stroke-width="7" stroke-linecap="round"/>
  <path d="M34 91l18-6-12-12-6 18Z" fill="$_navy"/>
''';

String _listeningIcon() =>
    '''
  <path d="M37 72c0-23 14-39 32-39s32 16 32 39" fill="none" stroke="$_blue" stroke-width="10" stroke-linecap="round"/>
  <rect x="27" y="67" width="22" height="31" rx="10" fill="$_blue"/>
  <rect x="79" y="67" width="22" height="31" rx="10" fill="$_blue"/>
  <path d="M65 47c13 5 18 14 16 28" fill="none" stroke="#fff" stroke-width="5" stroke-linecap="round"/>
''';

String _trophyIcon() =>
    '''
  <path d="M43 35h42v28c0 15-9 25-21 25S43 78 43 63V35Z" fill="$_yellow" stroke="#D88C00" stroke-width="5"/>
  <path d="M43 44H30c0 18 10 27 22 27M85 44h13c0 18-10 27-22 27" fill="none" stroke="#D88C00" stroke-width="7" stroke-linecap="round"/>
  <path d="M64 88v15M48 104h32" stroke="$_orange" stroke-width="8" stroke-linecap="round"/>
  ${_starPath(cx: 64, cy: 58, r: 12, fill: '#fff', stroke: '#fff')}
''';

String _progressIcon() =>
    '''
  <path d="M34 91V68M64 91V47M94 91V31" stroke="$_green" stroke-width="16" stroke-linecap="round"/>
  <path d="M30 95h72" stroke="$_navy" stroke-width="6" stroke-linecap="round"/>
  ${_starPath(cx: 88, cy: 34, r: 13, fill: _yellow, stroke: '#F6B100')}
''';

String _profileIcon({required bool child}) =>
    '''
  <circle cx="64" cy="48" r="23" fill="$_skin" stroke="#F1A174" stroke-width="5"/>
  <path d="M41 45c5-21 31-30 49-10-15-2-27 0-40 9 8 4 17 5 29 2-13 10-26 11-38-1Z" fill="${child ? _hair : _navy}"/>
  <path d="M30 103c6-22 20-32 34-32s28 10 34 32H30Z" fill="${child ? _orange : _blue}" stroke="${child ? '#E46F00' : '#2B6EB4'}" stroke-width="5"/>
''';

String _reportIcon() =>
    '''
  <rect x="35" y="27" width="58" height="77" rx="10" fill="#fff" stroke="$_purple" stroke-width="6"/>
  <path d="M48 48h31M48 64h20M48 82h34" stroke="$_navy" stroke-width="6" stroke-linecap="round"/>
  <circle cx="86" cy="36" r="12" fill="$_yellow" stroke="#F6B100" stroke-width="4"/>
''';

String _worldIcon() =>
    '''
  <circle cx="64" cy="64" r="36" fill="$_blue" stroke="#2B6EB4" stroke-width="6"/>
  <path d="M43 48c12 4 19 1 26-6 8 8 17 10 28 7M35 70c17-6 29-4 39 5 8-5 17-7 27-5M64 29c-14 19-14 50 0 70M64 29c14 19 14 50 0 70" fill="none" stroke="#fff" stroke-width="5" stroke-linecap="round"/>
''';

String _compassIcon() =>
    '''
  <circle cx="64" cy="64" r="37" fill="#fff" stroke="$_orange" stroke-width="7"/>
  <path d="M77 38 66 70 39 88l11-32 27-18Z" fill="$_yellow" stroke="#D88C00" stroke-width="5" stroke-linejoin="round"/>
  <circle cx="64" cy="64" r="6" fill="$_orange"/>
''';

String _gardenIcon() =>
    '''
  <path d="M28 96c22-25 50-25 72 0H28Z" fill="$_green" stroke="#328C35" stroke-width="5"/>
  <path d="M64 88V50" stroke="#8B5A2B" stroke-width="9" stroke-linecap="round"/>
  <circle cx="50" cy="52" r="18" fill="#7BCB3A"/>
  <circle cx="76" cy="48" r="21" fill="$_green"/>
  <circle cx="78" cy="72" r="17" fill="#7BCB3A"/>
''';

String _offlineIcon() =>
    '''
  <path d="M36 55c18-15 38-15 56 0M48 70c10-8 22-8 32 0" fill="none" stroke="$_blue" stroke-width="9" stroke-linecap="round"/>
  <path d="M32 32l64 64" stroke="$_orange" stroke-width="9" stroke-linecap="round"/>
  <circle cx="64" cy="87" r="7" fill="$_blue"/>
''';

void _writeAppIconSources() {
  _write(
    'assets/branding/app_icon/android/foreground.svg',
    _symbolSvg(monochrome: false),
  );
  _write(
    'assets/branding/app_icon/android/background.svg',
    _svg(108, 108, '<rect width="108" height="108" rx="24" fill="$_cloud"/>'),
  );
  _write(
    'assets/branding/app_icon/android/monochrome.svg',
    _symbolSvg(monochrome: true),
  );
  _writePng('assets/branding/app_icon/android/play_store_512.png', 512);
  _writePng('assets/branding/app_icon/ios/app_icon_master_1024.png', 1024);
}

void _writeAndroidLauncherVectors() {
  _write(
    'apps/mobile/android/app/src/main/res/drawable/ic_launcher_foreground.xml',
    '''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path android:fillColor="$_orange" android:pathData="M17,76V34c0,-5 4,-8 9,-7c3,1 6,4 8,7l13,24l13,-24c2,-3 5,-6 9,-7c5,-1 9,2 9,7v42c0,5 -4,9 -9,9s-9,-4 -9,-9V55l-7,12c-3,5 -9,5 -12,0l-7,-12v21c0,5 -4,9 -9,9s-8,-4 -8,-9Z"/>
    <path android:fillColor="$_green" android:pathData="M84,43a9,9 0,1 0,18 0a9,9 0,1 0,-18 0"/>
    <path android:fillColor="$_green" android:pathData="M84,58h18v28c0,5 -4,9 -9,9s-9,-4 -9,-9z"/>
    <path android:fillColor="$_yellow" android:pathData="M91,18l4,9l10,1l-8,7l2,10l-8,-5l-9,5l2,-10l-8,-7l10,-1z"/>
</vector>
''',
  );
  _write(
    'apps/mobile/android/app/src/main/res/drawable/ic_launcher_monochrome.xml',
    '''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path android:fillColor="#FF000000" android:pathData="M17,76V34c0,-5 4,-8 9,-7c3,1 6,4 8,7l13,24l13,-24c2,-3 5,-6 9,-7c5,-1 9,2 9,7v42c0,5 -4,9 -9,9s-9,-4 -9,-9V55l-7,12c-3,5 -9,5 -12,0l-7,-12v21c0,5 -4,9 -9,9s-8,-4 -8,-9Z"/>
    <path android:fillColor="#FF000000" android:pathData="M84,43a9,9 0,1 0,18 0a9,9 0,1 0,-18 0"/>
    <path android:fillColor="#FF000000" android:pathData="M84,58h18v28c0,5 -4,9 -9,9s-9,-4 -9,-9z"/>
    <path android:fillColor="#FF000000" android:pathData="M91,18l4,9l10,1l-8,7l2,10l-8,-5l-9,5l2,-10l-8,-7l10,-1z"/>
</vector>
''',
  );
  _write(
    'apps/mobile/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
    '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/mi_academy_icon_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />
</adaptive-icon>
''',
  );
  _write(
    'apps/mobile/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml',
    '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/mi_academy_icon_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />
</adaptive-icon>
''',
  );
}

void _copyRuntimeSvgs() {
  final roots = [
    'logo',
    'mascot',
    'icons/learning',
    'icons/navigation',
    'icons/profile',
    'icons/rewards',
  ];
  for (final root in roots) {
    final sourceDir = Directory('assets/branding/$root');
    if (!sourceDir.existsSync()) continue;
    for (final file in sourceDir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.svg')) continue;
      final relative = file.path
          .replaceAll(r'\', '/')
          .substring('assets/branding/'.length);
      final target = 'packages/design_system/assets/branding/$relative';
      _write(target, file.readAsStringSync());
    }
  }
}

String _svg(int width, int height, String body) =>
    '''<svg width="$width" height="$height" viewBox="0 0 $width $height">
$body
</svg>
''';

String _starPath({
  required num cx,
  required num cy,
  required num r,
  required String fill,
  required String stroke,
}) {
  final points = <String>[];
  for (var i = 0; i < 10; i++) {
    final radius = i.isEven ? r : r * 0.45;
    final angle = -math.pi / 2 + i * math.pi / 5;
    points.add(
      '${cx + math.cos(angle) * radius},${cy + math.sin(angle) * radius}',
    );
  }
  return '<path d="M${points.join(' L')} Z" fill="$fill" stroke="$stroke" stroke-width="4" stroke-linejoin="round"/>';
}

String _questionMark(num x, num y, {double scale = 1}) =>
    '<path transform="translate($x $y) scale($scale)" d="M0 14c0-12 9-21 22-21 12 0 21 8 21 19 0 9-5 14-13 18-5 3-7 5-7 11H10c0-11 4-16 13-21 5-3 7-5 7-9 0-4-3-7-8-7s-8 4-8 10H0Zm9 44a9 9 0 1 0 18 0 9 9 0 0 0-18 0Z" fill="$_blue"/>';

void _write(String path, String content) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

void _writePng(String path, int size) {
  final pixels = Uint8List(size * size * 4);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final i = (y * size + x) * 4;
      final dx = (x - size / 2) / (size / 2);
      final dy = (y - size / 2) / (size / 2);
      final inside = dx * dx + dy * dy < 0.82;
      pixels[i] = inside ? 244 : 255;
      pixels[i + 1] = inside ? 246 : 255;
      pixels[i + 2] = inside ? 250 : 255;
      pixels[i + 3] = 255;
      if (inside &&
          x > size * .18 &&
          x < size * .58 &&
          y > size * .34 &&
          y < size * .72) {
        pixels[i] = 255;
        pixels[i + 1] = 138;
        pixels[i + 2] = 0;
      }
      if (inside &&
          x > size * .66 &&
          x < size * .78 &&
          y > size * .42 &&
          y < size * .76) {
        pixels[i] = 76;
        pixels[i + 1] = 175;
        pixels[i + 2] = 80;
      }
      if ((x - size * .72) * (x - size * .72) +
              (y - size * .28) * (y - size * .28) <
          size * size * .006) {
        pixels[i] = 255;
        pixels[i + 1] = 210;
        pixels[i + 2] = 63;
      }
    }
  }
  final png = _encodePng(size, size, pixels);
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(png);
}

Uint8List _encodePng(int width, int height, Uint8List rgba) {
  final out = BytesBuilder();
  out.add([137, 80, 78, 71, 13, 10, 26, 10]);
  void chunk(String type, List<int> data) {
    final typeBytes = type.codeUnits;
    out.add(_u32(data.length));
    out.add(typeBytes);
    out.add(data);
    out.add(_u32(_crc32([...typeBytes, ...data])));
  }

  chunk('IHDR', [..._u32(width), ..._u32(height), 8, 6, 0, 0, 0]);
  final raw = BytesBuilder();
  for (var y = 0; y < height; y++) {
    raw.addByte(0);
    raw.add(rgba.sublist(y * width * 4, (y + 1) * width * 4));
  }
  chunk('IDAT', ZLibEncoder().convert(raw.takeBytes()));
  chunk('IEND', []);
  return out.takeBytes();
}

List<int> _u32(int value) => [
  (value >> 24) & 0xff,
  (value >> 16) & 0xff,
  (value >> 8) & 0xff,
  value & 0xff,
];

int _crc32(List<int> bytes) {
  var crc = 0xffffffff;
  for (final byte in bytes) {
    crc ^= byte;
    for (var k = 0; k < 8; k++) {
      crc = (crc & 1) != 0 ? 0xedb88320 ^ (crc >> 1) : crc >> 1;
    }
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}

class _MascotPose {
  const _MascotPose({
    this.wave = false,
    this.thumb = false,
    this.ok = false,
    this.handToChin = false,
    this.armsUp = false,
    this.handsTogether = false,
    this.eyesClosed = false,
    this.star = false,
    this.heart = false,
    this.mark,
    required this.mouth,
  });

  final bool wave;
  final bool thumb;
  final bool ok;
  final bool handToChin;
  final bool armsUp;
  final bool handsTogether;
  final bool eyesClosed;
  final bool star;
  final bool heart;
  final String? mark;
  final String mouth;
}
