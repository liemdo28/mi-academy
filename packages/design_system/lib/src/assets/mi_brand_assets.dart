/// Typed brand asset registry for Mi Academy.
///
/// Feature and game code should use these enums/components rather than raw
/// asset paths. Production replacement should happen by adding approved files
/// at the expected paths or by changing this registry.
abstract class MiBrandAssets {
  static const package = 'design_system';
  static const _base = 'packages/design_system/assets/branding';
  static const _placeholderBase = '$_base/placeholders';

  static String logo(MiLogoVariant variant) => switch (variant) {
        MiLogoVariant.primary => '$_base/logo/mi_academy_primary.svg',
        MiLogoVariant.stacked => '$_base/logo/mi_academy_stacked.svg',
        MiLogoVariant.symbol => '$_base/logo/mi_academy_symbol.svg',
        MiLogoVariant.monochrome => '$_base/logo/mi_academy_monochrome.svg',
      };

  static String mascot(MiMascotEmotion emotion) =>
      '$_base/mascot/${emotion.assetName}.svg';

  static String brandIcon(MiBrandIcon icon) =>
      '$_base/icons/${icon.familyName}/${icon.assetName}.svg';

  static String logoFallback(MiLogoVariant variant) =>
      '$_placeholderBase/logo_placeholder.svg';

  static String mascotFallback(MiMascotEmotion emotion) =>
      '$_placeholderBase/mascot_placeholder.svg';

  static String brandIconFallback(MiBrandIcon icon) =>
      '$_placeholderBase/logo_placeholder.svg';

  static const expectedProductionLogoFiles = {
    MiLogoVariant.primary: 'assets/branding/logo/mi_academy_primary.svg',
    MiLogoVariant.stacked: 'assets/branding/logo/mi_academy_stacked.svg',
    MiLogoVariant.symbol: 'assets/branding/logo/mi_academy_symbol.svg',
    MiLogoVariant.monochrome: 'assets/branding/logo/mi_academy_monochrome.svg',
  };

  static Map<MiMascotEmotion, String> get expectedProductionMascotFiles => {
        for (final emotion in MiMascotEmotion.values)
          emotion: 'assets/branding/mascot/${emotion.assetName}.svg',
      };

  static Map<MiBrandIcon, String> get expectedProductionBrandIconFiles => {
        for (final icon in MiBrandIcon.values)
          icon:
              'assets/branding/icons/${icon.familyName}/${icon.assetName}.svg',
      };
}

enum MiLogoVariant {
  primary,
  stacked,
  symbol,
  monochrome,
}

enum MiMascotEmotion {
  welcome,
  success,
  thinking,
  confused,
  excited,
  encouraging,
  tryAgain,
  celebration,
  apology,
  love,
  sleeping,
  surprised,
}

extension MiMascotEmotionAssetName on MiMascotEmotion {
  String get assetName => switch (this) {
        MiMascotEmotion.welcome => 'welcome',
        MiMascotEmotion.success => 'success',
        MiMascotEmotion.thinking => 'thinking',
        MiMascotEmotion.confused => 'confused',
        MiMascotEmotion.excited => 'excited',
        MiMascotEmotion.encouraging => 'encouraging',
        MiMascotEmotion.tryAgain => 'try_again',
        MiMascotEmotion.celebration => 'celebration',
        MiMascotEmotion.apology => 'apology',
        MiMascotEmotion.love => 'love',
        MiMascotEmotion.sleeping => 'sleeping',
        MiMascotEmotion.surprised => 'surprised',
      };
}

enum MiBrandIcon {
  alphabet,
  numbers,
  logic,
  memory,
  writing,
  listening,
  rewardStar,
  achievement,
  progress,
  profile,
  parent,
  world,
  exploration,
  garden,
  offline,
  report,
}

extension MiBrandIconAssetName on MiBrandIcon {
  String get familyName => switch (this) {
        MiBrandIcon.alphabet => 'learning',
        MiBrandIcon.numbers => 'learning',
        MiBrandIcon.logic => 'learning',
        MiBrandIcon.memory => 'learning',
        MiBrandIcon.writing => 'learning',
        MiBrandIcon.listening => 'learning',
        MiBrandIcon.rewardStar => 'rewards',
        MiBrandIcon.achievement => 'rewards',
        MiBrandIcon.progress => 'rewards',
        MiBrandIcon.profile => 'profile',
        MiBrandIcon.parent => 'profile',
        MiBrandIcon.world => 'navigation',
        MiBrandIcon.exploration => 'navigation',
        MiBrandIcon.garden => 'navigation',
        MiBrandIcon.offline => 'navigation',
        MiBrandIcon.report => 'profile',
      };

  String get assetName => switch (this) {
        MiBrandIcon.alphabet => 'alphabet',
        MiBrandIcon.numbers => 'numbers',
        MiBrandIcon.logic => 'logic',
        MiBrandIcon.memory => 'memory',
        MiBrandIcon.writing => 'writing',
        MiBrandIcon.listening => 'listening',
        MiBrandIcon.rewardStar => 'reward_star',
        MiBrandIcon.achievement => 'achievement',
        MiBrandIcon.progress => 'progress',
        MiBrandIcon.profile => 'profile',
        MiBrandIcon.parent => 'parent',
        MiBrandIcon.world => 'world',
        MiBrandIcon.exploration => 'exploration',
        MiBrandIcon.garden => 'garden',
        MiBrandIcon.offline => 'offline',
        MiBrandIcon.report => 'report',
      };
}

enum MiBrandAnimationMode {
  auto,
  still,
  subtle,
}
