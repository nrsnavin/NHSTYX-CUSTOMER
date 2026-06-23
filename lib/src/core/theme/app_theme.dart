import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modern retail theme — royal blue primary with a muted-yellow accent,
/// on clean white surfaces with hairline borders and generous spacing.
class AppTheme {
  const AppTheme._();

  static const Color brandBlue = Color(0xFF00539C); // royal blue — primary
  static const Color accentYellow = Color(0xFFFFD662); // muted yellow — accent
  static const Color ink = Color(0xFF14213D); // dark navy text
  static const Color subtle = Color(0xFF64748B); // blue-grey secondary text
  static const Color line = Color(0xFFE3E8EF); // hairline border
  static const Color surfaceMuted = Color(0xFFEEF2F8); // chip / placeholder bg

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: brandBlue,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFD6E4F2),
      onPrimaryContainer: Color(0xFF00305C),
      secondary: accentYellow,
      onSecondary: Color(0xFF3D2E00),
      secondaryContainer: Color(0xFFFFF1C2),
      onSecondaryContainer: Color(0xFF4A3A00),
      surface: Colors.white,
      onSurface: ink,
      surfaceContainerHighest: surfaceMuted,
      outline: Color(0xFFC3CEDD),
      outlineVariant: line,
      error: Color(0xFFDC2626),
    );
    return _base(scheme, Brightness.light);
  }

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: Color(0xFF8FBEE8),
      onPrimary: Color(0xFF002A4E),
      primaryContainer: Color(0xFF003B6F),
      onPrimaryContainer: Color(0xFFD6E4F2),
      secondary: accentYellow,
      onSecondary: Color(0xFF3D2E00),
      secondaryContainer: Color(0xFF5A4A12),
      onSecondaryContainer: Color(0xFFFFF1C2),
      surface: Color(0xFF0F1722),
      onSurface: Color(0xFFE8EEF5),
      surfaceContainerHighest: Color(0xFF1B2735),
      outline: Color(0xFF3A4A5E),
      outlineVariant: Color(0xFF273241),
      error: Color(0xFFF87171),
    );
    return _base(scheme, Brightness.dark);
  }

  static ThemeData _base(ColorScheme scheme, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        systemOverlayStyle:
            isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      ),
      textTheme: _textTheme(scheme.onSurface),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w500),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        hintStyle: const TextStyle(color: subtle),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.surfaceContainerHighest,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? scheme.onSurface : subtle,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? scheme.onSurface : subtle,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.onSurface,
        contentTextStyle: TextStyle(color: scheme.surface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  static TextTheme _textTheme(Color color) {
    return TextTheme(
      headlineMedium: TextStyle(color: color, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      titleLarge: TextStyle(color: color, fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleMedium: TextStyle(color: color, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: color, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(color: color),
      labelLarge: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }
}
