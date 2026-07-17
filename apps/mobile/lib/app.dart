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
    return MaterialApp.router(
      title: 'MI Academy',
      debugShowCheckedModeBanner: false,
      theme: MiTheme.light,
      darkTheme: MiTheme.light,
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
