import 'package:flutter/material.dart';

final adminTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF6C63FF),
    brightness: Brightness.light,
  ),
  appBarTheme: const AppBarTheme(centerTitle: false),
  cardTheme: CardTheme(elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    filled: true,
  ),
);
