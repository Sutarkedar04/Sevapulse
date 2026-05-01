// lib/core/theme/theme_extensions.dart
import 'package:flutter/material.dart';

extension ThemeColors on BuildContext {
  /// Primary text color (onSurface)
  Color get primaryText => Theme.of(this).colorScheme.onSurface;
  
  /// Secondary text color (with opacity for less emphasis)
  Color get secondaryText => Theme.of(this).colorScheme.onSurface.withOpacity(0.6);
  
  /// Surface color (cards, dialogs, etc.)
  Color get surfaceColor => Theme.of(this).colorScheme.surface;
  
  /// Card color (with surfaceVariant fallback)
  Color get cardColor => Theme.of(this).colorScheme.surfaceVariant;
  
  /// Check if dark mode is enabled
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  
  /// Primary color from theme
  Color get primaryColor => Theme.of(this).primaryColor;
  
  /// Secondary/Accent color
  Color get accentColor => Theme.of(this).colorScheme.secondary;
  
  /// Error color
  Color get errorColor => Theme.of(this).colorScheme.error;
  
  /// Background color
  Color get backgroundColor => Theme.of(this).colorScheme.background;
  
  /// Scaffold background color
  Color get scaffoldBackgroundColor => Theme.of(this).scaffoldBackgroundColor;
}