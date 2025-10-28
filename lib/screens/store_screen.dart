import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sudoku_game/providers/game_provider.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final accent = game.accentColor;
    return Scaffold(
      appBar: AppBar(title: const Text('Store')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stars, color: accent),
                  const SizedBox(width: 8),
                  Text('${game.points} pts',
                      style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 16),
              // _storeCard(
              //   context,
              //   title: 'Solve Puzzle',
              //   subtitle: 'Instantly solve current puzzle',
              //   cost: 1000,
              //   accent: accent,
              //   onPressed: () async {
              //     final ok =
              //         await context.read<GameProvider>().purchaseSolvePuzzle();
              //     _toast(context, ok ? 'Puzzle solved!' : 'Not enough points');
              //   },
              // ),
              _storeCard(
                context,
                title: 'Extra Hint',
                subtitle: '+1 hint',
                cost: 30,
                accent: accent,
                onPressed: () async {
                  final ok =
                      await context.read<GameProvider>().purchaseExtraHint();
                  _toast(context, ok ? 'Hint added!' : 'Not enough points');
                },
              ),
              _storeCard(
                context,
                title: 'Custom Color Theme',
                subtitle: game.customThemeUnlocked
                    ? 'Unlocked — choose below'
                    : 'Use custom accent colors instead of red',
                cost: 500,
                accent: accent,
                buttonText: game.customThemeUnlocked ? 'Unlocked' : null,
                onPressed: game.customThemeUnlocked
                    ? null
                    : () async {
                        final ok = await context
                            .read<GameProvider>()
                            .purchaseCustomTheme();
                        _toast(
                            context,
                            ok
                                ? 'Custom theme unlocked!'
                                : 'Not enough points');
                      },
              ),
              if (game.customThemeUnlocked) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: _colorOptions.map((opt) {
                    final selected = game.accentColorName == opt.$1;
                    return ChoiceChip(
                      label: Text(opt.$1),
                      selected: selected,
                      onSelected: (_) => context
                          .read<GameProvider>()
                          .setAccentColorName(opt.$1),
                      selectedColor: opt.$2.withOpacity(0.2),
                      labelStyle: TextStyle(color: selected ? opt.$2 : null),
                      side: BorderSide(
                          color: selected ? opt.$2 : Colors.transparent),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  static final List<(String, Color)> _colorOptions = [
    ('blue', Colors.blue),
    ('black', Colors.black),
    ('grey', Colors.grey),
    ('yellow', Colors.amber),
    ('green', Colors.green),
    ('brown', Colors.brown),
    ('pink', Colors.pink),
    ('red', Colors.red),
  ];

  Widget _storeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required int cost,
    required Color accent,
    VoidCallback? onPressed,
    String? buttonText,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: accent),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.stars, color: accent, size: 18),
                      const SizedBox(width: 6),
                      Text('$cost'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: onPressed == null ? Colors.grey : accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: onPressed,
              icon: const Icon(Icons.shopping_cart_checkout),
              label: Text(buttonText ?? 'Buy'),
            )
          ],
        ),
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
