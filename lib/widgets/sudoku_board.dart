import 'dart:math';
import 'package:flutter/material.dart';

/// SudokuBoard renders a 9x9 Sudoku grid with 3x3 boxes emphasized.
/// It supports selection, same-number highlighting, and subtle row/column shading.
class SudokuBoard extends StatelessWidget {
  final List<List<int>> grid; // 9x9
  final Set<Point<int>> fixed; // given cells
  final Point<int>? selected;
  final ValueChanged<Point<int>> onSelect;
  // When a correct input occurs, pass the target cell and increment blinkKey to trigger a 500ms blink.
  final Point<int>? blinkCell;
  final int blinkKey;

  const SudokuBoard({
    super.key,
    required this.grid,
    required this.fixed,
    required this.selected,
    required this.onSelect,
    this.blinkCell,
    this.blinkKey = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive square board sized to fit width with padding
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth, // full width
          child: AspectRatio(
            aspectRatio: 1,
            child: _Board(
              grid: grid,
              fixed: fixed,
              selected: selected,
              onSelect: onSelect,
              blinkCell: blinkCell,
              blinkKey: blinkKey,
            ),
          ),
        );
      },
    );
  }
}

class _Board extends StatelessWidget {
  final List<List<int>> grid;
  final Set<Point<int>> fixed;
  final Point<int>? selected;
  final ValueChanged<Point<int>> onSelect;
  final Point<int>? blinkCell;
  final int blinkKey;

  const _Board({
    required this.grid,
    required this.fixed,
    required this.selected,
    required this.onSelect,
    required this.blinkCell,
    required this.blinkKey,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sel = selected;
    final selectedValue = sel == null ? 0 : grid[sel.x][sel.y];

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(
          painter: _GridPainter(colorScheme: colorScheme),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 9,
            ),
            itemCount: 81,
            itemBuilder: (context, index) {
              final r = index ~/ 9;
              final c = index % 9;
              final v = grid[r][c];
              final isFixed = fixed.contains(Point(r, c));
              final isSelected = sel?.x == r && sel?.y == c;
              final isSameNumber = selectedValue != 0 && v == selectedValue;
              final sameRow = sel?.x == r;
              final sameCol = sel?.y == c;

              Color bg = Colors.transparent;
              if (sameRow || sameCol) {
                bg =
                    Colors.grey.withOpacity(0.16); // light grey row/col shading
              }
              if (isSameNumber) {
                bg = colorScheme.primary
                    .withOpacity(0.3); // brighter same-number highlight
              }
              if (isSelected) {
                bg = Colors.red
                    .withOpacity(0.24); // selected cell highlight in red
              }

              final textColor = colorScheme.onSurface;
              final fontWeight = isFixed ? FontWeight.bold : FontWeight.w500;

              Widget cell = Container(
                alignment: Alignment.center,
                color: bg,
                child: Text(
                  v == 0 ? '' : '$v',
                  style: TextStyle(
                    fontSize: 20,
                    color: textColor,
                    fontWeight: fontWeight,
                  ),
                ),
              );

              // Blink effect for the cell that just received a correct input
              final shouldBlink = blinkCell?.x == r && blinkCell?.y == c;
              if (shouldBlink) {
                cell = TweenAnimationBuilder<double>(
                  key: ValueKey('blink_${blinkKey}_${r}_${c}'),
                  tween: Tween(begin: 0.5, end: 0.0),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        child!,
                        IgnorePointer(
                          child: Opacity(
                            opacity: value,
                            child: Container(
                                color: Colors.yellowAccent.withOpacity(0.4)),
                          ),
                        ),
                      ],
                    );
                  },
                  child: cell,
                );
              }

              return InkWell(
                onTap: () => onSelect(Point(r, c)),
                child: cell,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final ColorScheme colorScheme;
  _GridPainter({required this.colorScheme});

  @override
  void paint(Canvas canvas, Size size) {
    final thin = Paint()
      ..color = colorScheme.outline.withOpacity(0.4)
      ..strokeWidth = 1;
    final thick = Paint()
      ..color = colorScheme.outline
      ..strokeWidth = 2.5;

    // Draw cell borders
    final cell = size.width / 9;
    for (var i = 0; i <= 9; i++) {
      final p = cell * i;
      canvas.drawLine(
          Offset(p, 0), Offset(p, size.height), (i % 3 == 0) ? thick : thin);
      canvas.drawLine(
          Offset(0, p), Offset(size.width, p), (i % 3 == 0) ? thick : thin);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
