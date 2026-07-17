import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:localization/localization.dart';
import 'config/router.dart';

class MiAcademyApp extends ConsumerWidget {
  const MiAcademyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Real accessibility wiring, not just tokens on paper: the platform's
    // "increase contrast" setting swaps every semantic color that has an
    // `.hc` variant (docs/design/MI_DESIGN_SYSTEM.md §1).
    final theme = MiTheme.light(highContrast: MediaQuery.highContrastOf(context));
    return MaterialApp.router(
      title: 'MI Academy',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      routerConfig: routerProvider,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
      locale: const Locale('vi'),
    );
  }
}
