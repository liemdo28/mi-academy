import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:localization/localization.dart';
import 'config/router.dart';
import 'providers/providers.dart';

class MiAcademyApp extends ConsumerWidget {
  const MiAcademyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Falls back to 'vi' while the settings load and on load failure --
    // matches ParentSettingsSnapshot's own default.
    final language =
        ref.watch(parentSettingsProvider).valueOrNull?.language ?? 'vi';

    return MaterialApp.router(
      title: 'MI Academy',
      debugShowCheckedModeBanner: false,
      // 1.0 ships a single real (light) theme only. A dark theme was
      // previously "supported" by pointing darkTheme at the light theme,
      // which isn't a real dark mode -- removed rather than faked.
      theme: MiTheme.light,
      routerConfig: routerProvider,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
      locale: Locale(language),
    );
  }
}
