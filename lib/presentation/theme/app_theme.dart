import 'package:flutter/material.dart';

/// Beeline-inspired telecom super-app Material 3 themes (Dark default, Light,
/// and High-Contrast Senior Mode).
abstract final class AppTheme {
  // Brand & Surface Palette (Minimalist Luxury Fintech)
  static const Color beelineYellow = Color(0xFFFFCC00);
  static const Color beelineYellowBright = Color(0xFFFFD400);
  static const Color obsidianBlack = Color(0xFF09090B);
  static const Color carbonSurface = Color(0xFF16161A);
  static const Color carbonBorder = Color(0x0FFFFFFF);
  static const Color comicOutline = Color(0xFF141418);
  static const Color carbonElevated = Color(0xFF1E1E24);
  static const Color carbonInput = Color(0xFF1C1C22);
  static const Color coolGray = Color(0xFF9E9EA9);
  static const Color offWhite = Color(0xFFF5F5F7);

  // Semantic Status Colors (used strictly for subtle dots & numbers)
  static const Color coralRed = Color(0xFFFF453A);
  static const Color electricGreen = Color(0xFF30D158);
  static const Color warmAmber = Color(0xFFFF9F0A);

  static ThemeData dark({bool seniorMode = false}) {
    const scheme = ColorScheme.dark(
      primary: beelineYellow,
      onPrimary: obsidianBlack,
      primaryContainer: Color(0xFF332900),
      onPrimaryContainer: beelineYellowBright,
      secondary: beelineYellowBright,
      onSecondary: obsidianBlack,
      secondaryContainer: carbonElevated,
      onSecondaryContainer: Colors.white,
      surface: carbonSurface,
      onSurface: Colors.white,
      onSurfaceVariant: coolGray,
      surfaceContainerLow: Color(0xFF141418),
      surfaceContainerHighest: carbonElevated,
      outline: carbonBorder,
      outlineVariant: carbonBorder,
      error: coralRed,
      onError: Colors.white,
    );
    return _buildTheme(scheme, isDark: true, seniorMode: seniorMode);
  }

  static ThemeData light({bool seniorMode = false}) {
    const scheme = ColorScheme.light(
      primary: beelineYellow,
      onPrimary: obsidianBlack,
      primaryContainer: Color(0xFFFFF3BF),
      onPrimaryContainer: obsidianBlack,
      secondary: obsidianBlack,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFEBEBF0),
      onSecondaryContainer: obsidianBlack,
      surface: Colors.white,
      onSurface: obsidianBlack,
      onSurfaceVariant: Color(0xFF5C5C66),
      surfaceContainerLow: Color(0xFFF0F0F4),
      surfaceContainerHighest: Color(0xFFE5E5EA),
      outline: Color(0xFFD8D8E0),
      outlineVariant: Color(0xFFE4E4EC),
      error: coralRed,
      onError: Colors.white,
    );
    return _buildTheme(scheme, isDark: false, seniorMode: seniorMode);
  }

  static ThemeData _buildTheme(
    ColorScheme scheme, {
    required bool isDark,
    required bool seniorMode,
  }) {
    final scaffoldBg = isDark ? obsidianBlack : offWhite;
    final cardBg = isDark ? carbonSurface : Colors.white;
    final borderColor = seniorMode
        ? (isDark ? Colors.white70 : obsidianBlack)
        : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E5EC));

    final baseText = isDark
        ? Typography.material2021().white
        : Typography.material2021().black;

    final textTheme = baseText.copyWith(
      headlineSmall: baseText.headlineSmall?.copyWith(
        fontSize: seniorMode ? 30 : 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        fontSize: seniorMode ? 24 : 21,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      titleMedium: baseText.titleMedium?.copyWith(
        fontSize: seniorMode ? 20 : 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      bodyLarge: baseText.bodyLarge?.copyWith(
        fontSize: seniorMode ? 18 : 15,
        height: 1.45,
      ),
      bodyMedium: baseText.bodyMedium?.copyWith(
        fontSize: seniorMode ? 16 : 14,
        height: 1.4,
      ),
      labelLarge: baseText.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: isDark ? Colors.white : obsidianBlack,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: borderColor,
            width: seniorMode ? 1.8 : 0.5,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? carbonElevated : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? carbonElevated : const Color(0xFFF0F0F4),
        selectedColor: beelineYellow,
        checkmarkColor: obsidianBlack,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : obsidianBlack,
          size: 16,
        ),
        labelStyle: WidgetStateTextStyle.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected
                ? obsidianBlack
                : (isDark ? Colors.white : obsidianBlack),
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
          );
        }),
        secondaryLabelStyle: const TextStyle(
          color: obsidianBlack,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: beelineYellow,
          foregroundColor: obsidianBlack,
          minimumSize: Size(0, seniorMode ? 54 : 46),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white : obsidianBlack,
          minimumSize: Size(0, seniorMode ? 54 : 46),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          side: BorderSide(color: borderColor, width: 1.5),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
          shape: const StadiumBorder(),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? carbonSurface : Colors.white,
        indicatorColor: beelineYellow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected
                ? (isDark ? beelineYellow : obsidianBlack)
                : (isDark ? coolGray : const Color(0xFF5C5C66)),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? obsidianBlack
                : (isDark ? coolGray : const Color(0xFF5C5C66)),
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? carbonSurface : Colors.white,
        indicatorColor: beelineYellow,
        selectedIconTheme: const IconThemeData(color: obsidianBlack),
        unselectedIconTheme: IconThemeData(
          color: isDark ? coolGray : const Color(0xFF5C5C66),
        ),
        selectedLabelTextStyle: TextStyle(
          color: isDark ? beelineYellow : obsidianBlack,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: isDark ? coolGray : const Color(0xFF5C5C66),
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? carbonInput : const Color(0xFFF0F0F4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: beelineYellow, width: 1.5),
        ),
      ),
    );
  }
}
