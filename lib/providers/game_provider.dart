import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sudoku_game/data/sudoku_generator.dart';
import 'package:sudoku_game/data/storage_service.dart';
import 'package:sudoku_game/models/sudoku_board_model.dart';
import 'package:sudoku_game/models/leaderboard_entry.dart';

/// GameProvider holds the entire game state:
/// - current Sudoku board and difficulty
/// - selected cell
/// - timer (elapsed seconds)
/// - number usage counts and move validation
/// - persistence of current game and leaderboard on completion
class GameProvider extends ChangeNotifier {
  final _storage = StorageService();

  SudokuBoardModel _board = SudokuBoardModel.empty();
  String? _difficulty; // 'Easy' | 'Medium' | 'Hard' | 'Expert'
  Point<int>? _selected;

  int _elapsedSeconds = 0;
  int _startEpochMillis = 0; // used with elapsed to track pause/resume
  Timer? _timer;

  // Hints state
  int _hintsLeft = 3;
  List<List<int>>? _solutionCache; // computed on demand for hints

  // Meta
  List<LeaderboardEntry> _leaderboard = [];

  // Points and upgrades
  int _points = 0;
  bool _customThemeUnlocked = false;
  String _accentColorName = 'deep purple';

  // Completion event
  bool _justCompleted = false;
  int _lastEarnedPoints = 0;

  SudokuBoardModel get board => _board;
  String? get difficulty => _difficulty;
  Point<int>? get selected => _selected;
  int get elapsedSeconds => _elapsedSeconds;
  List<LeaderboardEntry> get leaderboard => List.unmodifiable(_leaderboard);
  int get hintsLeft => _hintsLeft;

  int get points => _points;
  bool get customThemeUnlocked => _customThemeUnlocked;
  String get accentColorName => _accentColorName;

  bool get justCompleted => _justCompleted;
  int get lastEarnedPoints => _lastEarnedPoints;

  bool get isRunning => _timer != null && _timer!.isActive;

  // Accent color helper
  Color get accentColor {
    switch (_accentColorName) {
      case 'purple':
        return Colors.purple;
      case 'deep purple':
        return Colors.deepPurple;
      case 'blue':
        return Colors.blue;
      case 'black':
        return Colors.black;
      case 'grey':
        return Colors.grey;
      case 'yellow':
        return Colors.amber;
      case 'green':
        return Colors.green;
      case 'brown':
        return Colors.brown;
      case 'pink':
        return Colors.pinkAccent;
      default:
        return Colors.red;
    }
  }

  Future<void> loadPersistedGame() async {
    // Load meta/progress
    _leaderboard = await _storage.loadLeaderboard();
    // Ensure leaderboard is always kept to top 4 fastest times
    _leaderboard.sort((a, b) => a.seconds.compareTo(b.seconds));
    if (_leaderboard.length > 4) {
      _leaderboard = _leaderboard.sublist(0, 4);
      // Persist trimmed list
      unawaited(_storage.saveLeaderboard(_leaderboard));
    }
    _points = await _storage.loadPoints();
    _customThemeUnlocked = await _storage.loadThemeUnlocked();
    _accentColorName = await _storage.loadAccentColorName() ?? 'deep purple';

    // Load current game if any
    final state = await _storage.loadGameState();
    if (state != null) {
      final grid = SudokuBoardModel.deserializeGrid(state['grid'] as String);
      final fixedMask = state['fixed'] as String;
      final fixed = <Point<int>>{};
      for (var i = 0; i < 81; i++) {
        if (fixedMask[i] == '1') {
          fixed.add(Point(i ~/ 9, i % 9));
        }
      }
      _board = SudokuBoardModel(grid: grid, fixed: fixed);
      _difficulty = state['difficulty'] as String;
      _startEpochMillis = state['startEpochMillis'] as int;
      _elapsedSeconds = state['elapsedSeconds'] as int;
      _solutionCache = null; // recompute on demand
      _resumeTimer();
    }

    // Load global hints balance (persists across games). Default to 3 for first-time players.
    final globalHints = await _storage.loadHintsBalance();
    if (globalHints != null) {
      _hintsLeft = globalHints;
    } else {
      // Backward compatibility: if there was a saved per-game hints count, use it; otherwise start with 3.
      final legacyHints = state != null ? state['hintsLeft'] as int? : null;
      _hintsLeft = legacyHints ?? 3;
      await _storage.saveHintsBalance(_hintsLeft);
    }
  }

  Future<void> newGame(String difficulty) async {
    _difficulty = difficulty;
    _board = SudokuGenerator.generate(difficulty);
    _selected = null;
    _elapsedSeconds = 0;
    _startEpochMillis = DateTime.now().millisecondsSinceEpoch;
    // Do not reset hints on new game; hints persist globally.
    _solutionCache = null;
    _justCompleted = false;
    _lastEarnedPoints = 0;
    _startTimer();
    await _persist();
    notifyListeners();
  }

  void select(int r, int c) {
    _selected = Point(r, c);
    notifyListeners();
  }

  /// Attempt to set [value] at the selected cell. Returns true if successful.
  bool inputNumber(int value) {
    if (_selected == null) return false;
    final r = _selected!.x;
    final c = _selected!.y;
    if (_board.isFixed(r, c)) return false;
    if (!_board.canPlace(r, c, value)) return false;
    _board.setCell(r, c, value);
    _onBoardChanged();
    return true;
  }

  void clearCell() {
    if (_selected == null) return;
    final r = _selected!.x;
    final c = _selected!.y;
    if (_board.isFixed(r, c)) return;
    _board.setCell(r, c, 0);
    _onBoardChanged();
  }

  void resetBoard() {
    // Clears all non-fixed cells
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (!_board.isFixed(r, c)) _board.setCell(r, c, 0);
      }
    }
    _onBoardChanged();
  }

  void _onBoardChanged() {
    // Invalidate cached solution on any change
    _solutionCache = null;
    if (_board.isComplete) {
      _onCompleted();
    } else {
      _persist();
      notifyListeners();
    }
  }

  void _onCompleted() async {
    _stopTimer();
    final totalSeconds = _elapsedSeconds + _currentSessionSeconds();
    final entry = LeaderboardEntry(
      difficulty: _difficulty ?? 'Unknown',
      seconds: totalSeconds,
      completedAt: DateTime.now(),
    );
    _leaderboard.add(entry);
    // Sort fastest first and keep only top 4
    _leaderboard.sort((a, b) => a.seconds.compareTo(b.seconds));
    if (_leaderboard.length > 4) {
      _leaderboard = _leaderboard.sublist(0, 4);
    }
    await _storage.saveLeaderboard(_leaderboard);

    // Award points based on difficulty
    final diff = (_difficulty ?? 'Easy').toLowerCase();
    int earned = 10;
    if (diff.startsWith('med'))
      earned = 15;
    else if (diff.startsWith('hard'))
      earned = 20;
    else if (diff.startsWith('exp')) earned = 30;
    _points += earned;
    _lastEarnedPoints = earned;
    _justCompleted = true;
    await _storage.savePoints(_points);

    await _storage.clearGameState();
    _timer?.cancel();
    notifyListeners();
  }

  // Public actions for Store
  bool spendPoints(int cost) {
    if (_points < cost) return false;
    _points -= cost;
    _storage.savePoints(_points);
    notifyListeners();
    return true;
  }

  void addPoints(int p) {
    _points += p;
    _storage.savePoints(_points);
    notifyListeners();
  }

  Future<bool> purchaseExtraHint() async {
    if (!spendPoints(30)) return false;
    _hintsLeft += 1;
    await _storage.saveHintsBalance(_hintsLeft);
    await _persist();
    notifyListeners();
    return true;
  }

  // DEV-ONLY: set absolute points balance while in debug/profile builds
  void setPointsDev(int value) {
    assert(() {
      _points = max(0, value);
      _storage.savePoints(_points);
      notifyListeners();
      return true;
    }());
  }

  Future<bool> purchaseSolvePuzzle() async {
    if (!spendPoints(1000)) return false;
    final sol = _getSolution();
    if (sol == null) return false;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        _board.setCell(r, c, sol[r][c]);
      }
    }
    _onBoardChanged();
    return true;
  }

  Future<bool> purchaseCustomTheme() async {
    if (_customThemeUnlocked) return true;
    if (!spendPoints(500)) return false;
    _customThemeUnlocked = true;
    await _storage.saveThemeUnlocked(true);
    notifyListeners();
    return true;
  }

  Future<void> setAccentColorName(String name) async {
    _accentColorName = name;
    await _storage.saveAccentColorName(name);
    notifyListeners();
  }

  void clearCompletionFlag() {
    _justCompleted = false;
    _lastEarnedPoints = 0;
  }

  // Timer handling
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  void _resumeTimer() {
    if (_timer?.isActive ?? false) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  int _currentSessionSeconds() {
    if (_startEpochMillis == 0) return 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = (now - _startEpochMillis) ~/ 1000;
    return diff;
  }

  /// Returns the displayed elapsed seconds = saved elapsed + running session.
  int get displaySeconds => _elapsedSeconds + _currentSessionSeconds();

  Future<void> pauseAndPersist() async {
    _elapsedSeconds = displaySeconds;
    _startEpochMillis = DateTime.now().millisecondsSinceEpoch;
    await _persist();
  }

  Future<void> _persist() async {
    if (_difficulty == null) return;
    final gridStr = _board.serializeGrid();
    final fixedMask = List.generate(81, (i) {
      final r = i ~/ 9;
      final c = i % 9;
      return _board.isFixed(r, c) ? '1' : '0';
    }).join();
    await _storage.saveGameState(
      grid: gridStr,
      fixedMask: fixedMask,
      difficulty: _difficulty!,
      startEpochMillis: _startEpochMillis,
      elapsedSeconds: _elapsedSeconds,
      hintsLeft: _hintsLeft,
    );
  }

  /// Counts usage of 1..9. A number is maxed out when count == 9.
  List<int> get numberCounts => SudokuGenerator.countNumbers(_board.grid);

  /// Use a hint to fill a correct value in the selected or a random empty cell.
  /// Returns true if a hint was used and a cell filled.
  bool useHint() {
    if (_hintsLeft <= 0 || _board.isComplete) return false;

    // Prefer selected cell if it's empty and not fixed
    Point<int>? target = _selected;
    if (target == null ||
        _board.isFixed(target.x, target.y) ||
        _board.getCell(target.x, target.y) != 0) {
      // Find a random empty non-fixed cell
      final empties = <Point<int>>[];
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (!_board.isFixed(r, c) && _board.getCell(r, c) == 0) {
            empties.add(Point(r, c));
          }
        }
      }
      if (empties.isEmpty) return false;
      empties.shuffle(Random());
      target = empties.first;
    }

    final solution = _getSolution();
    if (solution == null) return false;
    final r = target.x, c = target.y;
    final correct = solution[r][c];
    if (correct <= 0) return false;

    _board.setCell(r, c, correct);
    _hintsLeft = max(0, _hintsLeft - 1);
    // Persist the global hints balance
    _storage.saveHintsBalance(_hintsLeft);
    _onBoardChanged();
    return true;
  }

  // Compute or return cached solution using backtracking based on the original fixed clues.
  List<List<int>>? _getSolution() {
    if (_solutionCache != null) return _solutionCache;

    // Build a grid that has the current state but we only need to solve the puzzle; to ensure correctness
    // we solve starting from the original fixed clues plus current correct entries. Using current grid is OK
    // as solver will fill remaining according to Sudoku rules.
    final g = List.generate(9, (r) => List<int>.from(_board.grid[r]));

    bool solve() {
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (g[r][c] == 0) {
            for (var v = 1; v <= 9; v++) {
              if (_canPlace(g, r, c, v)) {
                g[r][c] = v;
                if (solve()) return true;
                g[r][c] = 0;
              }
            }
            return false;
          }
        }
      }
      return true;
    }

    bool ok = solve();
    if (!ok) return null;
    _solutionCache = g.map((row) => List<int>.from(row)).toList();
    return _solutionCache;
  }

  bool _canPlace(List<List<int>> g, int r, int c, int v) {
    for (var i = 0; i < 9; i++) {
      if (g[r][i] == v) return false;
      if (g[i][c] == v) return false;
    }
    final br = (r ~/ 3) * 3;
    final bc = (c ~/ 3) * 3;
    for (var rr = br; rr < br + 3; rr++) {
      for (var cc = bc; cc < bc + 3; cc++) {
        if (g[rr][cc] == v) return false;
      }
    }
    return true;
  }
}
