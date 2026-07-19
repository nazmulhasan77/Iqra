class DailyAssignment {
  final String id;
  final String userId;
  final String programId;
  final DateTime assignmentDate;
  final List<QuranVerse> verses;
  final String status; // pending, completed, missed
  final DateTime? completedAt;

  DailyAssignment({
    required this.id,
    required this.userId,
    required this.programId,
    required this.assignmentDate,
    required this.verses,
    required this.status,
    this.completedAt,
  });

  factory DailyAssignment.fromMap(Map<String, dynamic> data) {
    var versesList = <QuranVerse>[];
    if (data['verses'] != null) {
      versesList = (data['verses'] as List)
          .map((verse) => QuranVerse.fromMap(verse))
          .toList();
    }

    return DailyAssignment(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      programId: data['programId'] ?? '',
      assignmentDate: data['assignmentDate']?.toDate() ?? DateTime.now(),
      verses: versesList,
      status: data['status'] ?? 'pending',
      completedAt: data['completedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'programId': programId,
      'assignmentDate': assignmentDate,
      'verses': verses.map((verse) => verse.toMap()).toList(),
      'status': status,
      'completedAt': completedAt,
    };
  }
}

class QuranVerse {
  final String surahName;
  final int surahNumber;
  final int verseNumber;
  final String arabicText;
  final String? translation;
  final String? transliteration;

  QuranVerse({
    required this.surahName,
    required this.surahNumber,
    required this.verseNumber,
    required this.arabicText,
    this.translation,
    this.transliteration,
  });

  factory QuranVerse.fromMap(Map<String, dynamic> data) {
    return QuranVerse(
      surahName: data['surahName'] ?? '',
      surahNumber: data['surahNumber'] ?? 0,
      verseNumber: data['verseNumber'] ?? 0,
      arabicText: data['arabicText'] ?? '',
      translation: data['translation'],
      transliteration: data['transliteration'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'surahName': surahName,
      'surahNumber': surahNumber,
      'verseNumber': verseNumber,
      'arabicText': arabicText,
      'translation': translation,
      'transliteration': transliteration,
    };
  }
}
