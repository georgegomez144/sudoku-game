/// Model representing a completed Sudoku game entry for the leaderboard.
/// Stores difficulty, elapsed time in seconds, and completion timestamp.
class LeaderboardEntry {
  final String difficulty; // 'Easy' | 'Medium' | 'Hard'
  final int seconds; // completion time in seconds
  final DateTime completedAt;

  LeaderboardEntry({
    required this.difficulty,
    required this.seconds,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'difficulty': difficulty,
        'seconds': seconds,
        'completedAt': completedAt.toIso8601String(),
      };

  static LeaderboardEntry fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        difficulty: json['difficulty'] as String,
        seconds: json['seconds'] as int,
        completedAt: DateTime.parse(json['completedAt'] as String),
      );
}
