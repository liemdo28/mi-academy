import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Supported locales in MI Academy.
const supportedLocales = [Locale('vi'), Locale('en')];

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
    final value =
        _translations[_locale.languageCode]?[key] ??
        _translations['en']?[key] ??
        key;
    if (params == null) return value;
    return _format(value, params);
  }

  String _format(String template, Map<String, dynamic> params) {
    var result = template;
    for (final entry in params.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value.toString());
    }
    return result;
  }
}

/// Extension on BuildContext for easy access to L10nService.
extension L10nExtension on BuildContext {
  L10nService get l10n => L10nService();
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
  },
};
