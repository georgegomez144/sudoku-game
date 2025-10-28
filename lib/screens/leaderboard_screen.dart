import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sudoku_game/providers/game_provider.dart';
import 'package:sudoku_game/models/leaderboard_entry.dart';

/// LeaderboardScreen lists top 4 completed games sorted from fastest to slowest.
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  String _format(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _badgeForIndex(int index) {
    // 0-based index: 0 -> gold, 1 -> silver, 2 -> bronze, 3 -> outlined
    if (index == 0) {
      return const CircleAvatar(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        child: Icon(Icons.military_tech),
      );
    } else if (index == 1) {
      return const CircleAvatar(
        backgroundColor: Colors.grey,
        foregroundColor: Colors.white,
        child: Icon(Icons.military_tech),
      );
    } else if (index == 2) {
      return const CircleAvatar(
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        child: Icon(Icons.military_tech),
      );
    } else {
      return CircleAvatar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey.shade400,
        child: const Icon(Icons.military_tech_outlined),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<GameProvider>().leaderboard;
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: entries.isEmpty
              ? const Center(child: Text('No completed games yet'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final LeaderboardEntry e = entries[index];
                    return ListTile(
                      leading: _badgeForIndex(index),
                      title: Text('${e.difficulty} • ${_format(e.seconds)}'),
                      subtitle: Text(
                        DateFormat("EEEE, MMM d 'at' h:mm a").format(
                          e.completedAt.toLocal(),
                        ),
                      ),
                      trailing: Text('#${index + 1}'),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
