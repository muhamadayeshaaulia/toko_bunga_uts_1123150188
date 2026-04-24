import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;   // ← state: false = light, true = dark
  bool get isDark => _isDark;
  // Menghasilkan ThemeMode yang akan dibaca MaterialApp
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  void toggle() {
    _isDark = !_isDark; 
    notifyListeners(); 
  }
}
 enum ThemeMode {
  system,
  light,
  dark,
}