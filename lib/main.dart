import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:sudoku_game/providers/game_provider.dart';
import 'package:sudoku_game/providers/theme_provider.dart';
import 'package:sudoku_game/screens/home_screen.dart';
import 'package:sudoku_game/screens/leaderboard_screen.dart';
import 'package:sudoku_game/screens/store_screen.dart';

// Entry point of the Sudoku game app. Sets up Providers and MaterialApp with theme modes.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeProvider = ThemeProvider();
  await themeProvider.load();
  final gameProvider = GameProvider();
  await gameProvider.loadPersistedGame();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => themeProvider),
        ChangeNotifierProvider(create: (_) => gameProvider),
      ],
      child: const SudokuApp(),
    ),
  );
}

class SudokuApp extends StatelessWidget {
  const SudokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final seed = game.accentColor;
    return MaterialApp(
      title: 'Sudoku',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme:
            ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
        useMaterial3: true,
        primaryColor: seed,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme:
            ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const RootScaffold(),
    );
  }
}

// RootScaffold manages the bottom navigation between Home and Leaderboard screens.
class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _index = 0;

  final _pages = const [
    HomeScreen(),
    LeaderboardScreen(),
    StoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: IndexedStack(
              key: ValueKey(_index),
              index: _index,
              children: _pages,
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.house),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.rosette),
            label: 'Leaders',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.bag),
            label: 'Upgrades',
          ),
        ],
      ),
    );
  }
}
