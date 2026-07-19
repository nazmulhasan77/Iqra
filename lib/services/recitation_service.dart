import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_assignment.dart';
import '../models/recitation_submission.dart';

class RecitationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get daily assignment for user
  Future<DailyAssignment?> getDailyAssignment(String userId) async {
    try {
      DateTime today = DateTime.now();
      DateTime startOfDay = DateTime(today.year, today.month, today.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      QuerySnapshot snapshot = await _firestore
          .collection('daily_assignments')
          .where('userId', isEqualTo: userId)
          .where('assignmentDate', isGreaterThanOrEqualTo: startOfDay)
          .where('assignmentDate', isLessThan: endOfDay)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return DailyAssignment.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get daily assignment: $e');
    }
  }

  // Create daily assignment
  Future<void> createDailyAssignment(DailyAssignment assignment) async {
    try {
      await _firestore
          .collection('daily_assignments')
          .doc(assignment.id)
          .set(assignment.toMap());
    } catch (e) {
      throw Exception('Failed to create daily assignment: $e');
    }
  }

  // Submit recitation
  Future<void> submitRecitation(RecitationSubmission submission) async {
    try {
      await _firestore
          .collection('recitation_submissions')
          .doc(submission.id)
          .set(submission.toMap());
    } catch (e) {
      throw Exception('Failed to submit recitation: $e');
    }
  }

  // Update assignment status
  Future<void> updateAssignmentStatus(
    String assignmentId,
    String status,
  ) async {
    try {
      await _firestore.collection('daily_assignments').doc(assignmentId).update({
        'status': status,
        'completedAt': status == 'completed' ? FieldValue.serverTimestamp() : null,
      });
    } catch (e) {
      throw Exception('Failed to update assignment status: $e');
    }
  }

  // Get submission history
  Future<List<RecitationSubmission>> getSubmissionHistory(
    String assignmentId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('recitation_submissions')
          .where('assignmentId', isEqualTo: assignmentId)
          .orderBy('submissionTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RecitationSubmission.fromMap(
                doc.data() as Map<String, dynamic>,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to get submission history: $e');
    }
  }
}
