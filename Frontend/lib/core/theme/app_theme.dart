// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Theme Colors
  static const Color lightPrimaryColor = Color(0xFF3498db);
  static const Color lightSecondaryColor = Color(0xFF2c3e50);
  static const Color lightAccentColor = Color(0xFF27ae60);
  static const Color lightBackgroundColor = Color(0xFFF8F9FA);
  static const Color lightSurfaceColor = Colors.white;
  static const Color lightErrorColor = Color(0xFFe74c3c);
  static const Color lightTextColor = Color(0xFF2c3e50);
  static const Color lightTextSecondaryColor = Color(0xFF7f8c8d);
  
  // ── Dark Theme Colors ───────────────────────────────────────────
  // Primary: slightly desaturated so it's not blinding on dark bg
  static const Color darkPrimaryColor         = Color(0xFF4EAEE5); // Softer blue (matches 0xFF3498db family)

  // Secondary: inverted from light's dark navy → light slate
  static const Color darkSecondaryColor       = Color(0xFFB0BEC5); // Blue-grey slate

  // Accent: same green family, slightly brightened for dark contrast
  static const Color darkAccentColor          = Color(0xFF2ecc71); // Bright green

  // Backgrounds: true dark, not pure black (easier on eyes)
  static const Color darkBackgroundColor      = Color(0xFF0F1923); // Deep navy-black
  static const Color darkSurfaceColor         = Color(0xFF1A2535); // Dark navy surface (mirrors light's navy secondary)
  static const Color darkCardColor            = Color(0xFF223044); // Slightly lighter card
  static const Color darkSurfaceVariant       = Color(0xFF2A3B52); // Input/chip backgrounds

  // Error: same red works on both themes
  static const Color darkErrorColor           = Color(0xFFe74c3c);

  // Text: inverted from light's dark navy → near-white
  static const Color darkTextColor            = Color(0xFFE8EDF2); // Soft white (not harsh #FFFFFF)
  static const Color darkTextSecondaryColor   = Color(0xFF8FA8C0); // Muted blue-grey (mirrors light's #7f8c8d)


  static const double borderRadius = 12.0;

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: lightPrimaryColor,
    scaffoldBackgroundColor: lightBackgroundColor,
    colorScheme: const ColorScheme.light(
      primary: lightPrimaryColor,
      secondary: lightAccentColor,
      surface: lightSurfaceColor,
      background: lightBackgroundColor,
      error: lightErrorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightTextColor,
      onBackground: lightTextColor,
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: lightTextColor,
      ),
      displayMedium: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: lightTextColor,
      ),
      displaySmall: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: lightTextColor,
      ),
      headlineLarge: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: lightTextColor,
      ),
      headlineMedium: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: lightTextColor,
      ),
      titleLarge: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: lightTextColor,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: lightTextColor,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        color: lightTextColor,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        color: lightTextSecondaryColor,
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightPrimaryColor,
        foregroundColor: Colors.white,
        // ✅ FIX: Change from double.infinity to a fixed width
        minimumSize: const Size(64, 48), // was: Size(double.infinity, 48)
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: 2,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: lightPrimaryColor,
        side: BorderSide(color: lightPrimaryColor),
        // ✅ FIX: Add minimumSize for consistency
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: lightPrimaryColor,
        minimumSize: const Size(48, 48), // ✅ Add minimumSize for text buttons
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightSurfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: lightPrimaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: lightErrorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(color: lightTextSecondaryColor),
      hintStyle: TextStyle(color: lightTextSecondaryColor),
    ),
    cardTheme: CardThemeData(
      color: lightSurfaceColor,
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightPrimaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: lightSurfaceColor,
      selectedItemColor: lightPrimaryColor,
      unselectedItemColor: lightTextSecondaryColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: lightPrimaryColor,
      unselectedLabelColor: lightTextSecondaryColor,
      indicatorColor: lightPrimaryColor,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade200,
      thickness: 1,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
    }),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: darkPrimaryColor,
    scaffoldBackgroundColor: darkBackgroundColor,
    colorScheme: const ColorScheme.dark(
  primary:          darkPrimaryColor,
  secondary:        darkAccentColor,
  surface:          darkSurfaceColor,
  surfaceVariant:   darkSurfaceVariant,  // ← used by inputs, chips
  background:       darkBackgroundColor,
  error:            darkErrorColor,
  onPrimary:        Colors.white,
  onSecondary:      Colors.white,
  onSurface:        darkTextColor,
  onBackground:     darkTextColor,
  onError:          Colors.white,
),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: darkTextColor,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: darkTextColor,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: darkTextColor,
      ),
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: darkTextColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: darkTextColor,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: darkTextColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: darkTextColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: darkTextColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: darkTextSecondaryColor,
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkPrimaryColor,
        foregroundColor: Colors.white,
        // ✅ FIX: Change from double.infinity to a fixed width
        minimumSize: const Size(64, 48), // was: Size(double.infinity, 48)
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: 2,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkPrimaryColor,
        side: BorderSide(color: darkPrimaryColor),
        // ✅ FIX: Add minimumSize for consistency
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: darkPrimaryColor,
        minimumSize: const Size(48, 48), // ✅ Add minimumSize for text buttons
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: darkPrimaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: darkErrorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(color: darkTextSecondaryColor),
      hintStyle: TextStyle(color: darkTextSecondaryColor),
    ),
    cardTheme: CardThemeData(
      color: darkCardColor,
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkSurfaceColor,
      foregroundColor: darkTextColor,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: darkTextColor,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: darkSurfaceColor,
      selectedItemColor: darkPrimaryColor,
      unselectedItemColor: darkTextSecondaryColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: darkPrimaryColor,
      unselectedLabelColor: darkTextSecondaryColor,
      indicatorColor: darkPrimaryColor,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade800,
      thickness: 1,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
    }),
  );
}