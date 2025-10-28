import 'dart:math';

/// Represents the state of a Sudoku board.
/// Holds the 9x9 grid, a set of fixed (given) cells, and helper methods
/// for validation and convenience.
class SudokuBoardModel {
  /// 9x9 grid, values 0 (empty) to 1..9.
  final List<List<int>> grid;

  /// Fixed cells that cannot be edited by the user.
  final Set<Point<int>> fixed;

  SudokuBoardModel({required this.grid, required this.fixed});

  factory SudokuBoardModel.empty() {
    return SudokuBoardModel(
      grid: List.generate(9, (_) => List.filled(9, 0)),
      fixed: <Point<int>>{},
    );
  }

  SudokuBoardModel copyWith({List<List<int>>? grid, Set<Point<int>>? fixed}) {
    return SudokuBoardModel(
      grid: grid ?? this._cloneGrid(),
      fixed: fixed ?? Set<Point<int>>.from(this.fixed),
    );
  }

  List<List<int>> _cloneGrid() => List.generate(9, (r) => List<int>.from(grid[r]));

  int getCell(int r, int c) => grid[r][c];

  void setCell(int r, int c, int v) {
    grid[r][c] = v;
  }

  bool isFixed(int r, int c) => fixed.contains(Point(r, c));

  List<int> row(int r) => List<int>.from(grid[r]);

  List<int> column(int c) => List<int>.generate(9, (r) => grid[r][c]);

  List<int> box(int br, int bc) {
    final startR = br * 3;
    final startC = bc * 3;
    final values = <int>[];
    for (var r = startR; r < startR + 3; r++) {
      for (var c = startC; c < startC + 3; c++) {
        values.add(grid[r][c]);
      }
    }
    return values;
  }

  /// Validates placing [value] at (r,c) obeys Sudoku rules.
  bool canPlace(int r, int c, int value) {
    if (value == 0) return true;
    for (var i = 0; i < 9; i++) {
      if (i != c && grid[r][i] == value) return false;
      if (i != r && grid[i][c] == value) return false;
    }
    final br = (r ~/ 3) * 3;
    final bc = (c ~/ 3) * 3;
    for (var rr = br; rr < br + 3; rr++) {
      for (var cc = bc; cc < bc + 3; cc++) {
        if ((rr != r || cc != c) && grid[rr][cc] == value) return false;
      }
    }
    return true;
  }

  /// Returns true if the board is completely filled and valid.
  bool get isComplete {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final v = grid[r][c];
        if (v == 0 || !canPlace(r, c, v)) return false;
      }
    }
    return true;
  }

  /// Serialize grid to a flat 81-char string (0..9 digits)
  String serializeGrid() {
    final sb = StringBuffer();
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        sb.write(grid[r][c]);
      }
    }
    return sb.toString();
  }

  /// Deserialize a flat 81-char string to a grid.
  static List<List<int>> deserializeGrid(String s) {
    final g = List.generate(9, (_) => List.filled(9, 0));
    var i = 0;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        g[r][c] = int.parse(s[i]);
        i++;
      }
    }
    return g;
  }
}
