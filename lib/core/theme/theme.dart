import 'package:flutter/material.dart';

/// Light and dark Material 3 themes for Anchor.
///
/// One seed color, dark mode first-class (night check-ins are the norm),
/// restrained by default (spec §2.6). `ThemeMode.system` is the app default;
/// the manual toggle lands in Manage in a later phase.
abstract final class AnchorTheme {
  /// The single seed color the whole palette derives from (spec §2.6).
  static const seed = Color(0xFF3A5A78);

  /// Optional habit swatches offered on Add/Edit (spec §2.2D). Cosmetic only,
  /// stored as hex strings; `null` means the default tint.
  static const habitSwatches = <String>[
    '#3A5A78',
    '#4E7A5A',
    '#8A6D3B',
    '#7A4E6D',
    '#B5533C',
    '#3C6E7A',
    '#5A5A5A',
  ];

  /// Parses a `#RRGGBB` habit swatch, or `null` when unset or malformed.
  static Color? swatchColor(String? hex) {
    if (hex == null) return null;
    final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    return value == null ? null : Color(0xFF000000 | value);
  }

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
