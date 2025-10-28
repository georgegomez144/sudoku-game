import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sudoku_game/models/leaderboard_entry.dart';
import 'package:sudoku_game/providers/game_provider.dart';
import 'package:sudoku_game/screens/play_screen.dart';

/// HomeScreen lets user select difficulty and start a new game.
/// The Play button is enabled only after a difficulty is selected.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedDifficulty;

  String _format(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<GameProvider>().leaderboard;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sudoku'),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Edit points (dev)',
              icon: const Icon(Icons.edit_note_outlined),
              onPressed: () => _showEditPointsDialog(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  // Points summary
                  Center(
                    child: Consumer<GameProvider>(
                      builder: (context, game, _) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars, color: game.accentColor),
                          const SizedBox(width: 8),
                          Text('${game.points} pts',
                              style: Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Progress summary: hints left and puzzles solved
                  Consumer<GameProvider>(
                    builder: (context, game, _) {
                      final accent = game.accentColor;
                      final chips = <Widget>[
                        _upgradeChip(
                          label: 'Hints Left: ${game.hintsLeft}',
                          color: accent,
                          icon: Icons.lightbulb_outline,
                        ),
                        _upgradeChip(
                          label: 'Puzzles Solved: ${game.leaderboard.length}',
                          color: accent,
                          icon: Icons.auto_fix_high_outlined,
                        ),
                      ];

                      if (game.customThemeUnlocked) {
                        chips.add(_upgradeChip(
                          label: 'Custom Theme (${game.accentColorName})',
                          color: game.accentColor,
                          icon: Icons.color_lens_outlined,
                        ));
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: chips,
                        ),
                      );
                    },
                  ),
                  Text('Choose difficulty', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _diffButton('Easy'),
                      _diffButton('Medium'),
                      _diffButton('Hard'),
                      _diffButton('Expert'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Play button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.read<GameProvider>().accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _selectedDifficulty == null
                        ? null
                        : () async {
                            await context
                                .read<GameProvider>()
                                .newGame(_selectedDifficulty!);
                            if (!mounted) return;
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (_, a, b) => const PlayScreen(),
                                transitionsBuilder: (_, anim, __, child) =>
                                    FadeTransition(opacity: anim, child: child),
                                transitionDuration:
                                    const Duration(milliseconds: 250),
                              ),
                            );
                          },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _diffButton(String label) {
    final selected = _selectedDifficulty == label;
    final accent = context.read<GameProvider>().accentColor;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _selectedDifficulty = label),
      selectedColor: accent.withOpacity(0.2),
      labelStyle: TextStyle(
          color: selected ? accent : null, fontWeight: FontWeight.w600),
      side: BorderSide(color: selected ? accent : Colors.transparent),
    );
  }

  Widget _upgradeChip(
      {required String label, required Color color, IconData? icon}) {
    return Chip(
      avatar: icon == null ? null : Icon(icon, size: 18, color: color),
      label: Text(label),
      side: BorderSide(color: color),
      shape: StadiumBorder(side: BorderSide(color: color)),
      backgroundColor: color.withOpacity(0.08),
      labelStyle: TextStyle(color: color),
    );
  }

  Future<void> _showEditPointsDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: context.read<GameProvider>().points.toString(),
    );
    final accent = context.read<GameProvider>().accentColor;
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Set Points (dev only)'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Points',
              hintText: 'Enter new balance',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: accent),
              onPressed: () {
                final v = int.tryParse(controller.text.trim());
                if (v != null) {
                  context.read<GameProvider>().setPointsDev(v);
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }
}
