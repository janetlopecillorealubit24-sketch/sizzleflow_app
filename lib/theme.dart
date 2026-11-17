import 'package:flutter/material.dart';

/// Same colours as the web version's style.css.
class SF {
  static const green = Color(0xFF176247);
  static const greenDark = Color(0xFF0E4A35);
  static const orange = Color(0xFFE68A22);
  static const bg = Color(0xFFFFF9EF);
  static const text = Color(0xFF24352D);
  static const muted = Color(0xFF6F776F);
  static const line = Color(0xFFE5DED0);
  static const danger = Color(0xFFC92A2A);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF176247), Color(0xFF238056), Color(0xFFE68A22)],
    stops: [0, 0.48, 1],
  );

  static const bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF9EF), Color(0xFFFFF6E8), Color(0xFFF6EAD7)],
    stops: [0, 0.58, 1],
  );

  static const mutedStyle = TextStyle(color: muted, fontSize: 13);
}

ThemeData buildTheme() {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: SF.line),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: SF.green,
      primary: SF.green,
      secondary: SF.orange,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: ThemeData.light().textTheme.apply(bodyColor: SF.text, displayColor: SF.text),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: SF.green, width: 1.5),
      ),
    ),
  );
}
