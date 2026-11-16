import 'package:flutter/material.dart';

/// App theme definition with Material 3 styling and scholarly aesthetic.
class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF8B4513); // Saddle Brown / Saffron
  static const Color primaryDark = Color(0xFF5C2D0C);
  static const Color accentGold = Color(0xFFD4AF37);
  static const Color tagBlue = Color(0xFF1E5F74);
  static const Color highlightBg = Color(0xFFFFF3CD);
  static const Color highlightText = Color(0xFF856404);
  static const Color inflectedBadgeText = Color(0xFF7A5800);
  static const Color inflectedBadgeBg = Color(0xFFF2E6C2);
  static const Color inflectedBadgeDarkText = Color(0xFFFFD54F);
  static const Color inflectedBadgeDarkBg = Color(0xFF3E3214);

  static const Color provenanceBadgeDarkBg = Color(0xFF3D2514);
  static const Color provenanceBadgeDarkText = Color(0xFFFFD5A5);

  static ThemeData lightTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentGold,
        surface: const Color(0xFFFBF9F5),
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF7F5F0),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF7F5F0),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C2523),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE8E4DC), width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF0ECE1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: const TextStyle(
          fontSize: 13,
          color: Color(0xFF3E3633),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD8D2C4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD8D2C4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE8E4DC),
        thickness: 1,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return const Color(0xFF8A827B);
        }),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: primaryColor.withValues(alpha: 0.15),
        backgroundColor: const Color(0xFFF0ECE1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            );
          }
          return const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B635E),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryColor);
          }
          return const IconThemeData(color: Color(0xFF6B635E));
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: const Color(0xFFF7F5F0),
        indicatorColor: primaryColor.withValues(alpha: 0.15),
        selectedLabelTextStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
        unselectedLabelTextStyle: const TextStyle(
          fontSize: 12,
          color: Color(0xFF6B635E),
        ),
        selectedIconTheme: const IconThemeData(color: primaryColor),
        unselectedIconTheme: const IconThemeData(color: Color(0xFF6B635E)),
      ),
    );
  }

  static ThemeData darkTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: const Color(0xFFE2A169),
        secondary: accentGold,
        surface: const Color(0xFF1E1C1A),
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF141312),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF141312),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFFEDE8E3),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF22201D),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF383430), width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2E2B27),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: const TextStyle(
          fontSize: 13,
          color: Color(0xFFE2DDD8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF22201D),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3E3A35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3E3A35)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFE2A169), width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2E2B27),
        thickness: 1,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFE2A169);
          }
          return const Color(0xFF8A827B);
        }),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: Color(0xFFEDE8E3),
        iconColor: Color(0xFFB0A9A2),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1A1917),
        indicatorColor: const Color(0xFFE2A169).withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE2A169),
            );
          }
          return const TextStyle(
            fontSize: 12,
            color: Color(0xFFB0A9A2),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFFE2A169));
          }
          return const IconThemeData(color: Color(0xFFB0A9A2));
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: const Color(0xFF141312),
        indicatorColor: const Color(0xFFE2A169).withValues(alpha: 0.2),
        selectedLabelTextStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE2A169),
        ),
        unselectedLabelTextStyle: const TextStyle(
          fontSize: 12,
          color: Color(0xFFB0A9A2),
        ),
        selectedIconTheme: const IconThemeData(color: Color(0xFFE2A169)),
        unselectedIconTheme: const IconThemeData(color: Color(0xFFB0A9A2)),
      ),
    );
  }
}
