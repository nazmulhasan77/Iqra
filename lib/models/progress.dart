class UserProgress {
  final String id;
  final String userId;
  final String programId;
  final int completedDays;
  final int totalVerses;
  final double completionPercentage;
  final int currentStreak;
  final int longestStreak;
  final int totalRewardPoints;
  final DateTime lastUpdated;

  UserProgress({
    required this.id,
    required this.userId,
    required this.programId,
    required this.completedDays,
    required this.totalVerses,
    required this.completionPercentage,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalRewardPoints,
    required this.lastUpdated,
  });

  factory UserProgress.fromMap(Map<String, dynamic> data) {
    return UserProgress(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      programId: data['programId'] ?? '',
      completedDays: data['completedDays'] ?? 0,
      totalVerses: data['totalVerses'] ?? 0,
      completionPercentage: (data['completionPercentage'] ?? 0).toDouble(),
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      totalRewardPoints: data['totalRewardPoints'] ?? 0,
      lastUpdated: data['lastUpdated']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'programId': programId,
      'completedDays': completedDays,
      'totalVerses': totalVerses,
      'completionPercentage': completionPercentage,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalRewardPoints': totalRewardPoints,
      'lastUpdated': lastUpdated,
    };
  }
}
