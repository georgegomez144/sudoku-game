import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sudoku_game/providers/game_provider.dart';

/// Displays the running elapsed time in mm:ss format.
class TimerWidget extends StatelessWidget {
  const TimerWidget({super.key});

  String _format(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final seconds = context.select<GameProvider, int>((g) => g.displaySeconds);
    final style = Theme.of(context).textTheme.titleLarge;
    return Text(_format(seconds), style: style);
  }
}
