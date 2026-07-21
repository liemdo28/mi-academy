import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Supported locales in MI Academy.
const supportedLocales = [
  Locale('vi'),
  Locale('en'),
];

/// Returns the appropriate Locale for a language code.
Locale localeFromCode(String code) {
  switch (code) {
    case 'en':
      return const Locale('en');
    case 'vi':
    default:
      return const Locale('vi');
  }
}

/// MI Academy localization delegate.
/// Place in MaterialApp.localizationsDelegates.
const localizationsDelegates = [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// MI Academy localization service.
///
/// Usage:
/// ```dart
/// MaterialApp(
///   locale: context.watch<L10nService>().locale,
///   localizationsDelegates: localizationsDelegates,
///   supportedLocales: supportedLocales,
/// );
/// ```
///
/// In widgets:
/// ```dart
/// context.l10n.welcome  // 'Welcome!'
/// context.l10n.login    // 'Login'
/// ```
///
/// To access the service:
/// ```dart
/// final l10n = context.read<L10nService>();
/// l10n.setLocale(const Locale('en'));
/// ```
class L10nService extends ChangeNotifier {
  Locale _locale = const Locale('vi');

  Locale get locale => _locale;

  /// Set the app locale. Valid codes: 'vi', 'en'.
  void setLocale(Locale locale) {
    if (!supportedLocales.contains(locale)) return;
    _locale = locale;
    notifyListeners();
  }

  /// Get a translated string by key.
  /// Falls back to English if the key is not found.
  String translate(String key, [Map<String, dynamic>? params]) {
    return translateForLocale(_locale, key, params);
  }

  /// Get a translated string for a specific locale without owning app state.
  static String translateForLocale(
    Locale locale,
    String key, [
    Map<String, dynamic>? params,
  ]) {
    final language = _translations.containsKey(locale.languageCode)
        ? locale.languageCode
        : 'vi';
    final value =
        _translations[language]?[key] ?? _translations['vi']?[key] ?? key;
    if (params == null) return value;
    return _formatTemplate(value, params);
  }

  static String _formatTemplate(
    String template,
    Map<String, dynamic> params,
  ) {
    var result = template;
    for (final entry in params.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value.toString());
    }
    return result;
  }
}

/// Extension on BuildContext for easy access to L10nService.
extension L10nExtension on BuildContext {
  String miT(String key, [Map<String, dynamic>? params]) {
    return L10nService.translateForLocale(
      Localizations.localeOf(this),
      key,
      params,
    );
  }
}

/// Hardcoded translations for bootstrap (Flutter generate will replace this).
const _translations = {
  'vi': {
    'appName': 'MI Academy',
    'welcome': 'Chào mừng!',
    'login': 'Đăng nhập',
    'register': 'Đăng ký',
    'logout': 'Đăng xuất',
    'email': 'Email',
    'password': 'Mật khẩu',
    'parentDashboard': 'Phụ huynh',
    'childHome': 'Trang chủ',
    'settings': 'Cài đặt',
    'profile': 'Hồ sơ',
    'selectChild': 'Chọn hồ sơ trẻ',
    'createChild': 'Tạo hồ sơ trẻ',
    'nickname': 'Biệt danh',
    'ageGroup': 'Nhóm tuổi',
    'dailyPlan': 'Kế hoạch hôm nay',
    'lessons': 'Bài học',
    'games': 'Trò chơi',
    'rewards': 'Phần thưởng',
    'stars': 'Sao',
    'badges': 'Huy hiệu',
    'lessonComplete': 'Hoàn thành bài học',
    'greatJob': 'Làm tốt lắm!',
    'tryAgain': 'Thử lại',
    'continue': 'Tiếp tục',
    'pause': 'Tạm dừng',
    'resume': 'Tiếp tục',
    'hint': 'Gợi ý',
    'next': 'Tiếp theo',
    'back': 'Quay lại',
    'save': 'Lưu',
    'cancel': 'Hủy',
    'delete': 'Xóa',
    'confirm': 'Xác nhận',
    'loading': 'Đang tải...',
    'error': 'Đã xảy ra lỗi',
    'retry': 'Thử lại',
    'noInternet': 'Không có kết nối mạng',
    'offlineMode': 'Chế độ offline',
    'todayProgress': 'Tiến độ hôm nay',
    'weeklyReport': 'Báo cáo tuần này',
    'parentPIN': 'Mã PIN phụ huynh',
    'setPIN': 'Đặt mã PIN',
    'enterPIN': 'Nhập mã PIN',
    'changePIN': 'Đổi mã PIN',
    'audioSettings': 'Cài đặt âm thanh',
    'accessibility': 'Hỗ trợ đặc biệt',
    'correct': 'Đúng rồi!',
    'incorrect': 'Chưa đúng, thử lại nhé!',
    'homeGreeting': 'Chào {name}!',
    'homeMascotLabel': 'Bạn MI đang vẫy tay chào',
    'homeParentGateLabel': 'Khu vực phụ huynh, giữ 3 giây để mở',
    'homeStartLearning': 'Bắt đầu học',
    'homeContinueLearning': 'Tiếp tục học',
    'homePlayLearnGrow': 'Chơi, học, lớn lên mỗi ngày',
    'homeProgressTitle': 'Tiến độ hôm nay',
    'homeProgressEmpty': 'Sẵn sàng cho bài học đầu tiên',
    'homeProgressWithCount': '{count} nhiệm vụ trong kế hoạch',
    'homeStars': 'Sao',
    'homeBadges': 'Huy hiệu',
    'homeDailyMission': 'Nhiệm vụ hôm nay',
    'homeDailyMissionSubtitle': 'MI chọn vài hoạt động vừa sức cho con.',
    'homePlanLoadError': 'Không thể tải kế hoạch',
    'homeEmptyTitle': 'Chưa có nhiệm vụ hôm nay',
    'homeEmptySubtitle': 'MI sẽ gợi ý bài học mới sớm thôi!',
    'homeMinutes': '{count} phút',
    'homeLessonFallback': 'Bài học',
    'homeGameCategories': 'Góc học vui',
    'homeLettersTitle': 'ABC',
    'homeLettersSubtitle': 'Chữ cái',
    'homeNumbersTitle': '123',
    'homeNumbersSubtitle': 'Số học',
    'homeLogicTitle': 'Logic',
    'homeLogicSubtitle': 'Tư duy',
    'homeMemoryTitle': 'Trí nhớ',
    'homeMemorySubtitle': 'Ghi nhớ',
    'homeWorld': 'Bản đồ',
    'homeGarden': 'Vườn',
    'homeHome': 'Trang chủ',
  },
  'en': {
    'appName': 'MI Academy',
    'welcome': 'Welcome!',
    'login': 'Login',
    'register': 'Register',
    'logout': 'Logout',
    'email': 'Email',
    'password': 'Password',
    'parentDashboard': 'Parent Dashboard',
    'childHome': 'Home',
    'settings': 'Settings',
    'profile': 'Profile',
    'selectChild': 'Select Child Profile',
    'createChild': 'Create Child Profile',
    'nickname': 'Nickname',
    'ageGroup': 'Age Group',
    'dailyPlan': "Today's Plan",
    'lessons': 'Lessons',
    'games': 'Games',
    'rewards': 'Rewards',
    'stars': 'Stars',
    'badges': 'Badges',
    'lessonComplete': 'Lesson Complete',
    'greatJob': 'Great job!',
    'tryAgain': 'Try again',
    'continue': 'Continue',
    'pause': 'Pause',
    'resume': 'Resume',
    'hint': 'Hint',
    'next': 'Next',
    'back': 'Back',
    'save': 'Save',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'confirm': 'Confirm',
    'loading': 'Loading...',
    'error': 'Something went wrong',
    'retry': 'Retry',
    'noInternet': 'No internet connection',
    'offlineMode': 'Offline mode',
    'todayProgress': "Today's Progress",
    'weeklyReport': 'Weekly Report',
    'parentPIN': 'Parent PIN',
    'setPIN': 'Set PIN',
    'enterPIN': 'Enter PIN',
    'changePIN': 'Change PIN',
    'audioSettings': 'Audio Settings',
    'accessibility': 'Accessibility',
    'correct': 'Correct!',
    'incorrect': 'Not quite, try again!',
    'homeGreeting': 'Hi {name}!',
    'homeMascotLabel': 'MI is waving hello',
    'homeParentGateLabel': 'Parent area, hold for 3 seconds to open',
    'homeStartLearning': 'Start learning',
    'homeContinueLearning': 'Continue learning',
    'homePlayLearnGrow': 'Play, learn, and grow every day',
    'homeProgressTitle': "Today's progress",
    'homeProgressEmpty': 'Ready for the first lesson',
    'homeProgressWithCount': '{count} missions in the plan',
    'homeStars': 'Stars',
    'homeBadges': 'Badges',
    'homeDailyMission': "Today's missions",
    'homeDailyMissionSubtitle': 'MI picked a few just-right activities.',
    'homePlanLoadError': 'Could not load the plan',
    'homeEmptyTitle': 'No missions yet today',
    'homeEmptySubtitle': 'MI will suggest a new lesson soon.',
    'homeMinutes': '{count} min',
    'homeLessonFallback': 'Lesson',
    'homeGameCategories': 'Learning corner',
    'homeLettersTitle': 'ABC',
    'homeLettersSubtitle': 'Letters',
    'homeNumbersTitle': '123',
    'homeNumbersSubtitle': 'Numbers',
    'homeLogicTitle': 'Logic',
    'homeLogicSubtitle': 'Thinking',
    'homeMemoryTitle': 'Memory',
    'homeMemorySubtitle': 'Remember',
    'homeWorld': 'World',
    'homeGarden': 'Garden',
    'homeHome': 'Home',
  },
};
