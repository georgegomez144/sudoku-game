import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sudoku_game/providers/game_provider.dart';
import 'package:sudoku_game/widgets/sudoku_board.dart';
import 'package:sudoku_game/widgets/number_pad.dart';
import 'package:sudoku_game/widgets/timer_widget.dart';

/// PlayScreen shows the active Sudoku game board, timer, and actions.
class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
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

  int _blinkKey = 0;
  Point<int>? _blinkCell;
  bool _storeOpen = false;

  void _toggleStoreSheet() {
    if (_storeOpen) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _storeOpen = true);
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Consumer<GameProvider>(builder: (context, g, _) {
                final accent = g.accentColor;
                final themeUnlocked = g.customThemeUnlocked;
                return ListView(
                  shrinkWrap: true,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stars, color: accent),
                        const SizedBox(width: 8),
                        Text('${g.points} pts',
                            style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      spacing: 8,
                      // runSpacing: 8,
                      // alignment: WrapAlignment.center,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final ok = await context
                                .read<GameProvider>()
                                .purchaseExtraHint();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(ok
                                    ? 'Hint added! (${context.read<GameProvider>().hintsLeft} total)'
                                    : 'Not enough points')));
                          },
                          icon: const Icon(Icons.lightbulb_outline),
                          label: const Text('Buy Hint (30)'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final ok = await context
                                .read<GameProvider>()
                                .purchaseSolvePuzzle();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(ok
                                    ? 'Puzzle solved!'
                                    : 'Not enough points')));
                          },
                          icon: const Icon(Icons.auto_fix_high_outlined),
                          label: const Text('Solve (1000)'),
                        ),
                        OutlinedButton.icon(
                          onPressed: themeUnlocked
                              ? null
                              : () async {
                                  final ok = await context
                                      .read<GameProvider>()
                                      .purchaseCustomTheme();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(ok
                                              ? 'Custom theme unlocked!'
                                              : 'Not enough points')));
                                },
                          icon: const Icon(Icons.color_lens_outlined),
                          label: Text(themeUnlocked
                              ? 'Theme Unlocked'
                              : 'Unlock Theme (500)'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              }),
            ),
          ),
        );
      },
    ).whenComplete(() {
      if (mounted) setState(() => _storeOpen = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final grid = game.board.grid;
    final fixed = game.board.fixed;
    final selected = game.selected;

    final counts = game.numberCounts; // length 9
    final disabled = List.generate(9, (i) => counts[i] >= 9);

    Widget board = SudokuBoard(
      grid: grid,
      fixed: fixed,
      selected: selected,
      onSelect: (p) => context.read<GameProvider>().select(p.x, p.y),
      blinkCell: _blinkCell,
      blinkKey: _blinkKey,
    );

    Widget controls = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        Center(
          child: FractionallySizedBox(
            widthFactor: 0.5, // 50% size for the 3x3 pad
            child: NumberPad(
              disabled: disabled,
              onNumber: (n) {
                final gp = context.read<GameProvider>();
                final ok = gp.inputNumber(n);
                if (!ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Incorrect number for this cell')),
                  );
                } else {
                  // Trigger a blink on the selected cell
                  setState(() {
                    _blinkCell = gp.selected == null
                        ? null
                        : Point(gp.selected!.x, gp.selected!.y);
                    _blinkKey++;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: game.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => context.read<GameProvider>().resetBoard(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => context.read<GameProvider>().clearCell(),
                icon: const Icon(Icons.clear),
                label: const Text('Clear Cell'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(game.difficulty ?? 'SUDOKU'),
        actions: [
          IconButton(
            tooltip: _storeOpen ? 'Hide Store' : 'Show Store',
            icon: const Icon(Icons.storefront_outlined),
            onPressed: _toggleStoreSheet,
          ),
          if (kDebugMode)
            IconButton(
              tooltip: 'Edit points (dev)',
              icon: const Icon(Icons.edit_note_outlined),
              onPressed: () => _showEditPointsDialog(context),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: OrientationBuilder(
                builder: (context, orientation) {
                  if (orientation == Orientation.portrait) {
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.timer_outlined),
                                SizedBox(width: 8),
                                TimerWidget(),
                              ],
                            ),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: game.accentColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 12),
                                  ),
                                  onPressed: game.hintsLeft == 0
                                      ? null
                                      : () {
                                          final used = context
                                              .read<GameProvider>()
                                              .useHint();
                                          if (!used) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'No valid cell for hint')),
                                            );
                                          } else {
                                            // brief feedback
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'Hint used. ${context.read<GameProvider>().hintsLeft} left')),
                                            );
                                          }
                                        },
                                  icon: const Icon(Icons.lightbulb_outline),
                                  label: Text('Hint (${game.hintsLeft})'),
                                ),
                                // Solve Puzzle button
                                TextButton.icon(
                                  onPressed: () async {
                                    final ok = await context
                                        .read<GameProvider>()
                                        .purchaseSolvePuzzle();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            ok
                                                ? 'Puzzle solved!'
                                                : 'Not enough points',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon:
                                      const Icon(Icons.auto_fix_high_outlined),
                                  label: const Text('Solve Puzzle'),
                                )
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 24),
                            child: board,
                          ),
                        ),
                        const SizedBox(height: 11),
                        controls,
                      ],
                    );
                  } else {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ConstrainedBox(
                            constraints: const BoxConstraints.tightFor(
                                height: double.infinity),
                            child: AspectRatio(aspectRatio: 1, child: board)),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: min(
                              380, MediaQuery.of(context).size.width * 0.35),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.timer_outlined),
                                      SizedBox(width: 8),
                                      TimerWidget(),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          foregroundColor: game.accentColor,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 12),
                                        ),
                                        onPressed: game.hintsLeft == 0
                                            ? null
                                            : () {
                                                final used = context
                                                    .read<GameProvider>()
                                                    .useHint();
                                                if (!used) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                        content: Text(
                                                            'No valid cell for hint')),
                                                  );
                                                } else {
                                                  // brief feedback
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            'Hint used. ${game.hintsLeft - 1} left')),
                                                  );
                                                }
                                              },
                                        icon:
                                            const Icon(Icons.lightbulb_outline),
                                        label: Text('Hint (${game.hintsLeft})'),
                                      ),
                                      // Solve Puzzle button
                                      TextButton.icon(
                                        onPressed: () async {
                                          final ok = await context
                                              .read<GameProvider>()
                                              .purchaseSolvePuzzle();
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  ok
                                                      ? 'Puzzle solved!'
                                                      : 'Not enough points',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(
                                            Icons.auto_fix_high_outlined),
                                        label: const Text('Solve'),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              controls,
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
