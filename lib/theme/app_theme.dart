import 'package:flutter/material.dart';

const Color kBgDark = Color(0xFF0d0d0f);
const Color kCardDark = Color(0xFF141416);
const Color kBorderDark = Color(0xFF222226);
const Color kIndigo = Color(0xFF4f46e5);
const Color kIndigoLight = Color(0xFFa5b4fc);
const Color kMutedGrey = Color(0xFF9ca3af);
const Color kShimmerBase = Color(0xFF2a2a2e);
const Color kShimmerHighlight = Color(0xFF3a3a3e);

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: kBgDark,
      colorScheme: const ColorScheme.dark(
        primary: kIndigo,
        secondary: kIndigoLight,
        surface: kCardDark,
        onSurface: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: kCardDark,
        selectedItemColor: kIndigo,
        unselectedItemColor: kMutedGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerColor: kBorderDark,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: kMutedGrey),
      ),
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kIndigo,
        brightness: Brightness.light,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: kIndigo,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
