# Sudoku Game Blueprint

This document tracks implemented features and upcoming sprints. Per guidelines, keep max 3 upcoming sprints.

## Implemented Features
- Flutter 3.x app with Provider (MVVM-like) architecture
- Dark-only theme; removed all LiquidGlass/LiquidStretch effects from the UI
- Dark, minimal background (no global background image)
- Bottom navigation: Home, Leaderboard, and Store (Material BottomNavigationBar; custom LiquidGlass bar removed)
- Home: Difficulty selection (Easy/Medium/Hard/Expert); Play enabled only after selection
- Play: Full-width 9x9 Sudoku board with 3x3 boxes, selection highlight, brighter same-number highlight, and light grey row/column shading
- Number pad (1–9) with automatic disabling when number fully used; 3x3 pad sized to 50% width
- Timer persists and continues across navigation
- Game state persistence (grid, fixed cells, difficulty, timer)
- Validation preventing conflicts; fixed cells locked
- Reset and Clear Cell actions
- Hints persist across games with correct auto-fill; new players start with 3 hints
- Leaderboard: stores only top 4 fastest times with badges (gold/silver/bronze/outlined) and local persistence (shared_preferences)
- Animated transitions between tabs and when navigating Home → Play
- Responsive layout; content centered and width-constrained on tablet/web
- Imports standardized to package: syntax
- Puzzle solvability guarantee during generation (prevents impossible boards)
- Fixed portrait layout issue on Play screen (proper Expanded placement)
- Fixed Home screen unbounded height error by wrapping leaderboard ListView in Expanded
- Store: Points system with upgrades (solve puzzle, extra hint, custom color theme)
- Home page shows total points and purchased upgrades
- Play screen shows purchased upgrades (chips)
- Play screen: Store opens as a bottom sheet with a toggle button on the AppBar; actions available: buy hint, solve puzzle, unlock theme
- New players start with an initial balance of 100 points

## Upcoming Sprints (max 3)
1. Performance tuning and bottleneck audit
   - Profile startup and frame times
   - Memoize expensive rebuilds and use const widgets where possible
   - Defer heavy work off the UI thread (isolates) where needed

2. Puzzle quality improvements
   - Option for guaranteed-unique puzzles (ensure single-solution generation)
   - Add difficulty calibration by clue distribution/solving metrics

3. UX polish
   - Add simple splash screen with app logo
   - Add confirmation dialogs for Reset/Clear actions
