import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sudoku_game/providers/game_provider.dart';

/// A 3x3 grid of number buttons (1..9). Disables a button when the number is fully used.
class NumberPad extends StatelessWidget {
  final List<bool> disabled; // length 9, true to disable number i+1
  final ValueChanged<int> onNumber;

  const NumberPad({super.key, required this.disabled, required this.onNumber});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    GameProvider game = context.read<GameProvider>();
    return AspectRatio(
      aspectRatio: 3 / 3,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          final number = index + 1;
          final isDisabled = disabled[index];
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDisabled ? colorScheme.surface : game.accentColor,
              foregroundColor: isDisabled
                  ? colorScheme.onSurface.withOpacity(0.5)
                  : Colors.white,
              disabledBackgroundColor: colorScheme.surfaceVariant,
              disabledForegroundColor: colorScheme.onSurface.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: isDisabled ? null : () => onNumber(number),
            child: Center(
              child: Text(
                '$number',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          );
        },
      ),
    );
  }
}
