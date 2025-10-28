import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sudoku_game/models/sudoku_board_model.dart';

/// Generates Sudoku puzzles by shuffling a base solved grid and removing clues
/// according to difficulty. This approach is fast and adequate for casual play.
class SudokuGenerator {
  static final _rand = Random();

  /// Returns a fully filled, valid Sudoku solution grid.
  static List<List<int>> _baseSolution() {
    // Standard base pattern: (r*3 + r~/3 + c) % 9 + 1
    final grid = List.generate(9, (_) => List.filled(9, 0));
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        grid[r][c] = ((r * 3 + r ~/ 3 + c) % 9) + 1;
      }
    }
    return grid;
  }

  /// Shuffles rows within bands, columns within stacks, and permutes numbers.
  static void _shuffleGrid(List<List<int>> g) {
    // Swap rows within each band
    for (var band = 0; band < 3; band++) {
      final rows = [0, 1, 2]..shuffle(_rand);
      final base = band * 3;
      final temp = List<List<int>>.from(g);
      for (var i = 0; i < 3; i++) {
        g[base + i] = List<int>.from(temp[base + rows[i]]);
      }
    }
    // Swap columns within each stack
    for (var stack = 0; stack < 3; stack++) {
      final colsOrder = [0, 1, 2]..shuffle(_rand);
      final base = stack * 3;
      final copy = List.generate(9, (r) => List<int>.from(g[r]));
      for (var i = 0; i < 3; i++) {
        for (var r = 0; r < 9; r++) {
          g[r][base + i] = copy[r][base + colsOrder[i]];
        }
      }
    }

    // Shuffle entire row bands
    final bands = [0, 1, 2]..shuffle(_rand);
    final temp = List.generate(9, (r) => List<int>.from(g[r]));
    for (var i = 0; i < 3; i++) {
      final srcBase = bands[i] * 3;
      final dstBase = i * 3;
      for (var j = 0; j < 3; j++) {
        g[dstBase + j] = List<int>.from(temp[srcBase + j]);
      }
    }

    // Shuffle entire column stacks
    final stacks = [0, 1, 2]..shuffle(_rand);
    final copy = List.generate(9, (r) => List<int>.from(g[r]));
    for (var i = 0; i < 3; i++) {
      final srcBase = stacks[i] * 3;
      final dstBase = i * 3;
      for (var j = 0; j < 3; j++) {
        for (var r = 0; r < 9; r++) {
          g[r][dstBase + j] = copy[r][srcBase + j];
        }
      }
    }

    // Permute numbers 1..9
    final nums = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle(_rand);
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        g[r][c] = nums[g[r][c] - 1];
      }
    }
  }

  /// Generate a puzzle by removing [holes] numbers from a solved grid.
  /// Ensures the resulting puzzle has at least one valid solution.
  static SudokuBoardModel generate(String difficulty) {
    final holes = switch (difficulty) {
      'Easy' => 40,
      'Medium' => 50,
      'Hard' => 60,
      'Expert' => 65,
      _ => 50,
    };

    // Try a few times to ensure solvable puzzle
    for (var attempt = 0; attempt < 30; attempt++) {
      final g = _baseSolution();
      _shuffleGrid(g);

      // Remove cells randomly
      final positions = List.generate(81, (i) => i)..shuffle(_rand);
      var removed = 0;
      while (removed < holes && positions.isNotEmpty) {
        final idx = positions.removeLast();
        final r = idx ~/ 9;
        final c = idx % 9;
        if (g[r][c] != 0) {
          g[r][c] = 0;
          removed++;
        }
      }

      // Validate solvability using a backtracking solver on a copy
      final copy = List.generate(9, (r) => List<int>.from(g[r]));
      if (!hasSolution(copy)) {
        continue; // try again
      }

      // Build fixed positions from non-zero cells
      final fixed = <Point<int>>{};
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (g[r][c] != 0) fixed.add(Point(r, c));
        }
      }

      return SudokuBoardModel(grid: g, fixed: fixed);
    }

    // Fallback: in the unlikely event all attempts failed, return a minimal puzzle
    final fallback = _baseSolution();
    _shuffleGrid(fallback);
    // Remove a modest number of cells to be safe
    var removed = 0;
    final positions = List.generate(81, (i) => i)..shuffle(_rand);
    while (removed < 40 && positions.isNotEmpty) {
      final idx = positions.removeLast();
      final r = idx ~/ 9;
      final c = idx % 9;
      if (fallback[r][c] != 0) {
        fallback[r][c] = 0;
        removed++;
      }
    }
    final fixed = <Point<int>>{};
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (fallback[r][c] != 0) fixed.add(Point(r, c));
      }
    }
    return SudokuBoardModel(grid: fallback, fixed: fixed);
  }

  /// Count how many of each number (1..9) currently exist on the board.
  static List<int> countNumbers(List<List<int>> g) {
    final counts = List.filled(10, 0);
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final v = g[r][c];
        if (v != 0) counts[v]++;
      }
    }
    return counts.sublist(1);
  }

  /// Basic backtracking to validate solvability (optional heavy). Not used by default
  /// to keep generation fast; kept here for potential future use.
  static bool hasSolution(List<List<int>> g) {
    int rr = -1, cc = -1;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (g[r][c] == 0) {
          rr = r;
          cc = c;
          r = 9;
          break;
        }
      }
    }
    if (rr == -1) return true;

    final usedRow = List.filled(10, false);
    final usedCol = List.filled(10, false);
    final usedBox = List.filled(10, false);
    for (var i = 1; i <= 9; i++) {
      if (g[rr].contains(i)) usedRow[i] = true;
      for (var r = 0; r < 9; r++) {
        if (g[r][cc] == i) usedCol[i] = true;
      }
    }
    final br = (rr ~/ 3) * 3;
    final bc = (cc ~/ 3) * 3;
    for (var r = br; r < br + 3; r++) {
      for (var c = bc; c < bc + 3; c++) {
        usedBox[g[r][c]] = true;
      }
    }

    for (var v = 1; v <= 9; v++) {
      if (usedRow[v] || usedCol[v] || usedBox[v]) continue;
      g[rr][cc] = v;
      if (hasSolution(g)) return true;
      g[rr][cc] = 0;
    }
    return false;
  }
}
