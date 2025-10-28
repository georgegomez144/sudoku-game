import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku_game/models/leaderboard_entry.dart';

/// StorageService wraps SharedPreferences for persisting
/// - theme mode
/// - leaderboard entries
/// - current game state (grid, fixed mask, difficulty, start time)
/// - points and upgrades
class StorageService {
  static const _themeModeKey = 'theme_mode';
  static const _leaderboardKey = 'leaderboard_entries';
  static const _gameGridKey = 'game_grid';
  static const _gameFixedKey = 'game_fixed';
  static const _gameDifficultyKey = 'game_difficulty';
  static const _gameStartEpochKey = 'game_start_epoch';
  static const _gameElapsedKey = 'game_elapsed_seconds';
  static const _gameHintsLeftKey = 'game_hints_left';

  // Global hint balance (persists across games)
  static const _hintsBalanceKey = 'hints_balance';

  // Points and upgrades
  static const _pointsKey = 'points_balance';
  static const _accentColorKey = 'accent_color_name';
  static const _themeUnlockedKey = 'custom_theme_unlocked';

  Future<void> saveThemeMode(String modeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, modeName);
  }

  Future<String?> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey);
  }

  Future<void> saveLeaderboard(List<LeaderboardEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final list = entries.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_leaderboardKey, list);
  }

  Future<List<LeaderboardEntry>> loadLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_leaderboardKey) ?? [];
    return list
        .map((s) =>
            LeaderboardEntry.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveGameState({
    required String grid,
    required String fixedMask,
    required String difficulty,
    required int startEpochMillis,
    required int elapsedSeconds,
    required int hintsLeft,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gameGridKey, grid);
    await prefs.setString(_gameFixedKey, fixedMask);
    await prefs.setString(_gameDifficultyKey, difficulty);
    await prefs.setInt(_gameStartEpochKey, startEpochMillis);
    await prefs.setInt(_gameElapsedKey, elapsedSeconds);
    await prefs.setInt(_gameHintsLeftKey, hintsLeft);
  }

  Future<Map<String, dynamic>?> loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final grid = prefs.getString(_gameGridKey);
    final fixed = prefs.getString(_gameFixedKey);
    final diff = prefs.getString(_gameDifficultyKey);
    final start = prefs.getInt(_gameStartEpochKey);
    final elapsed = prefs.getInt(_gameElapsedKey);
    if (grid == null ||
        fixed == null ||
        diff == null ||
        start == null ||
        elapsed == null) return null;
    final hintsLeft = prefs.getInt(_gameHintsLeftKey) ?? 3;
    return {
      'grid': grid,
      'fixed': fixed,
      'difficulty': diff,
      'startEpochMillis': start,
      'elapsedSeconds': elapsed,
      'hintsLeft': hintsLeft,
    };
  }

  Future<void> clearGameState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_gameGridKey);
    await prefs.remove(_gameFixedKey);
    await prefs.remove(_gameDifficultyKey);
    await prefs.remove(_gameStartEpochKey);
    await prefs.remove(_gameElapsedKey);
    await prefs.remove(_gameHintsLeftKey);
  }

  // Points
  Future<int> loadPoints() async {
    final prefs = await SharedPreferences.getInstance();
    // Default starting balance for new players is 100 points
    return prefs.getInt(_pointsKey) ?? 100;
  }

  Future<void> savePoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pointsKey, points);
  }

  // Accent color
  Future<void> saveAccentColorName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accentColorKey, name);
  }

  Future<String?> loadAccentColorName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accentColorKey);
  }

  // Upgrades
  Future<void> saveThemeUnlocked(bool unlocked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeUnlockedKey, unlocked);
  }

  Future<bool> loadThemeUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeUnlockedKey) ?? false;
  }

  // Global hints balance
  Future<int?> loadHintsBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_hintsBalanceKey);
  }

  Future<void> saveHintsBalance(int hints) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hintsBalanceKey, hints);
  }
}
