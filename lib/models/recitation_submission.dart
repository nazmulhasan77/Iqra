class RecitationSubmission {
  final String id;
  final String assignmentId;
  final String audioUrl;
  final DateTime submissionTime;
  final double verificationScore;
  final String verificationResult; // success, failed, partial
  final int retryNumber;
  final String? manualReviewStatus;
  final String? feedback;

  RecitationSubmission({
    required this.id,
    required this.assignmentId,
    required this.audioUrl,
    required this.submissionTime,
    required this.verificationScore,
    required this.verificationResult,
    required this.retryNumber,
    this.manualReviewStatus,
    this.feedback,
  });

  factory RecitationSubmission.fromMap(Map<String, dynamic> data) {
    return RecitationSubmission(
      id: data['id'] ?? '',
      assignmentId: data['assignmentId'] ?? '',
      audioUrl: data['audioUrl'] ?? '',
      submissionTime: data['submissionTime']?.toDate() ?? DateTime.now(),
      verificationScore: (data['verificationScore'] ?? 0).toDouble(),
      verificationResult: data['verificationResult'] ?? 'failed',
      retryNumber: data['retryNumber'] ?? 0,
      manualReviewStatus: data['manualReviewStatus'],
      feedback: data['feedback'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assignmentId': assignmentId,
      'audioUrl': audioUrl,
      'submissionTime': submissionTime,
      'verificationScore': verificationScore,
      'verificationResult': verificationResult,
      'retryNumber': retryNumber,
      'manualReviewStatus': manualReviewStatus,
      'feedback': feedback,
    };
  }
}
