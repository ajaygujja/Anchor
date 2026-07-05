import 'package:flutter/material.dart';

/// Light and dark Material 3 themes for Anchor.
///
/// One seed color, dark mode first-class (night check-ins are the norm),
/// restrained by default (spec §2.6). `ThemeMode.system` is the app default;
/// the manual toggle lands in Manage in a later phase.
abstract final class AnchorTheme {
  /// The single seed color the whole palette derives from (spec §2.6).
  static const seed = Color(0xFF3A5A78);

  static ThemeData get light => _themeFor(Brightness.light);

  static ThemeData get dark => _themeFor(Brightness.dark);

  static ThemeData _themeFor(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
      ),
    );
  }
}
