import 'package:mi_game_engines/mi_game_engines.dart';

/// Generic Placement Engine UI chrome (exit/pause/hint/retry/completion/
/// invalid-placement/malformed-content/announcements) shared by every
/// game built on the engine -- Shape Builder and Word Sorter today. This
/// is deliberately separate from each game's own title/description/
/// instruction text (which is genuinely game-specific and lives in each
/// game's own screen file / level content), matching this repository's
/// existing convention of passing locale-selected strings into a game
/// screen at the call site rather than hardcoding a single locale inside
/// the widget (see e.g. `game_registry.dart`'s `alphabet_explorer` entry).
///
/// See docs/content-review/shape-builder-review-checklist.csv and the
/// Games 11/12 final report for the exact key set Dev3 should fold into
/// `packages/localization/lib/l10n/app_{vi,en}.arb` for parity tracking
/// (this app does not yet consume ARB via generated `AppLocalizations`
/// for any screen -- see docs/release-audit.md RA-05 -- so these values
/// are supplied directly, the same way every other existing game screen
/// receives its locale-selected strings today).
PlacementLocalization buildPlacementLocalization(String locale) {
  final isEn = locale == 'en';
  return PlacementLocalization(
    exitLabel: isEn ? 'Exit' : 'Thoát',
    pauseLabel: isEn ? 'Pause' : 'Tạm dừng',
    resumeLabel: isEn ? 'Resume' : 'Tiếp tục',
    hintLabel: isEn ? 'Hint' : 'Gợi ý',
    retryLabel: isEn ? 'Play again' : 'Chơi lại',
    completionLabel: isEn ? 'Great job!' : 'Con làm rất tốt!',
    invalidPlacementMessage:
        isEn ? 'Not quite, try again!' : 'Chưa đúng vị trí, thử lại nhé!',
    malformedContentMessage: isEn
        ? 'This level is unavailable right now.'
        : 'Không thể tải cấp độ này lúc này.',
    removeLabel: isEn ? 'Remove' : 'Bỏ ra',
    selectedAnnouncement: (label) =>
        isEn ? '$label selected' : '$label đã được chọn',
    targetAnnouncement: (label, occupied, capacity) => isEn
        ? '$label, $occupied of $capacity filled'
        : '$label, đã đặt $occupied trên $capacity',
  );
}
