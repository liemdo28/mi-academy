import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'config/router.dart';
import 'config/theme.dart';

void main() {
  runApp(const MIAdminApp());
}

class MIAdminApp extends StatelessWidget {
  const MIAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MI Academy Admin',
      theme: adminTheme,
      routerConfig: adminRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
