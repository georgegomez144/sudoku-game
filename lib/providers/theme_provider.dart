import 'package:flutter/material.dart';
import 'package:sudoku_game/data/storage_service.dart';

/// ThemeProvider manages ThemeMode (system, light, dark) and persists the choice.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  final _storage = StorageService();

  ThemeMode get mode => _mode;

  Future<void> load() async {
    final saved = await _storage.loadThemeMode();
    if (saved == null) return;
    switch (saved) {
      case 'light':
        _mode = ThemeMode.light;
        break;
      case 'dark':
        _mode = ThemeMode.dark;
        break;
      default:
        _mode = ThemeMode.system;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final name = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _storage.saveThemeMode(name);
  }
}
