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
        backgroundColor: Color(0x00000000),
        foregroundColor: Colors.amber,
        child: Icon(
          Icons.military_tech,
          size: 40,
        ),
      );
    } else if (index == 1) {
      return const CircleAvatar(
        backgroundColor: Color(0x00000000),
        foregroundColor: Colors.grey,
        child: Icon(
          Icons.military_tech,
          size: 40,
        ),
      );
    } else if (index == 2) {
      return const CircleAvatar(
        backgroundColor: Color(0x00000000),
        foregroundColor: Colors.brown,
        child: Icon(
          Icons.military_tech,
          size: 40,
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> place = ['1st', '2nd', '3rd', '4th'];
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
                      leading: SizedBox(
                        width: 50,
                        child: Center(
                          child: Text(place[index],
                              style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                      title: Text('${e.difficulty} • ${_format(e.seconds)}'),
                      subtitle: Text(
                        DateFormat("EEEE, MMM d 'at' h:mm a").format(
                          e.completedAt.toLocal(),
                        ),
                      ),
                      trailing: _badgeForIndex(index),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
