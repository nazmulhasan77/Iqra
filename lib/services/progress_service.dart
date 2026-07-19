import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/progress.dart';

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user progress
  Future<UserProgress?> getUserProgress(String userId, String programId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('progress')
          .where('userId', isEqualTo: userId)
          .where('programId', isEqualTo: programId)
          .limit(1)
          .get()
          .then((snapshot) => snapshot.docs.first);

      if (doc.exists) {
        return UserProgress.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user progress: $e');
    }
  }

  // Create or update progress
  Future<void> updateProgress(UserProgress progress) async {
    try {
      await _firestore
          .collection('progress')
          .doc(progress.id)
          .set(progress.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update progress: $e');
    }
  }

  // Update progress after successful verification
  Future<void> updateProgressAfterVerification({
    required String userId,
    required String programId,
    required bool verificationSuccess,
  }) async {
    try {
      // Get current progress
      UserProgress? progress = await getUserProgress(userId, programId);

      if (progress == null) {
        // Create new progress
        progress = UserProgress(
          id: '$userId-$programId',
          userId: userId,
          programId: programId,
          completedDays: verificationSuccess ? 1 : 0,
          totalVerses: verificationSuccess ? 10 : 0, // Assuming 10 verses per day
          completionPercentage: verificationSuccess ? 0.5 : 0.0,
          currentStreak: verificationSuccess ? 1 : 0,
          longestStreak: verificationSuccess ? 1 : 0,
          totalRewardPoints: verificationSuccess ? 10 : 0, // 10 points per day
          lastUpdated: DateTime.now(),
        );
      } else {
        // Update existing progress
        if (verificationSuccess) {
          progress = UserProgress(
            id: progress.id,
            userId: progress.userId,
            programId: progress.programId,
            completedDays: progress.completedDays + 1,
            totalVerses: progress.totalVerses + 10,
            completionPercentage: progress.completionPercentage + 0.5,
            currentStreak: progress.currentStreak + 1,
            longestStreak: progress.currentStreak + 1 > progress.longestStreak
                ? progress.currentStreak + 1
                : progress.longestStreak,
            totalRewardPoints: progress.totalRewardPoints + 10,
            lastUpdated: DateTime.now(),
          );
        } else {
          // Reset streak on failed verification
          progress = UserProgress(
            id: progress.id,
            userId: progress.userId,
            programId: progress.programId,
            completedDays: progress.completedDays,
            totalVerses: progress.totalVerses,
            completionPercentage: progress.completionPercentage,
            currentStreak: 0,
            longestStreak: progress.longestStreak,
            totalRewardPoints: progress.totalRewardPoints,
            lastUpdated: DateTime.now(),
          );
        }
      }

      await updateProgress(progress);
    } catch (e) {
      throw Exception('Failed to update progress after verification: $e');
    }
  }
}
