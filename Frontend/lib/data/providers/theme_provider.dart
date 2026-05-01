// lib/data/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeData get currentTheme => _themeMode == ThemeMode.dark 
      ? AppTheme.darkTheme 
      : AppTheme.lightTheme;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    WidgetsBinding.instance.addPostFrameCallback((_) {
    notifyListeners();
  });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _themeMode == ThemeMode.dark);
  }

  void setLightMode() {
    _themeMode = ThemeMode.light;
    notifyListeners();
  }

  void setDarkMode() {
    _themeMode = ThemeMode.dark;
    notifyListeners();
  }
}