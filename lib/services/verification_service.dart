import 'dart:io';
import 'dart:math';
import 'package:firebase_storage/firebase_storage.dart';

class VerificationService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Random _random = Random();

  // Initialize - no-op for mock
  Future<void> initModel() async {
    print('Mock verification service initialized');
  }

  // Upload audio file to Firebase Storage
  Future<String> uploadAudioToStorage(File audioFile, String userId) async {
    try {
      String fileName = 'recitations/$userId/${DateTime.now().millisecondsSinceEpoch}.wav';
      Reference ref = _storage.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(audioFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload audio: $e');
    }
  }

  // Mock transcribe audio (for testing)
  Future<String> transcribeAudio(File audioFile) async {
    // For demonstration, return a mock transcription
    // In real app, this would use Vosk or another ASR service
    print('Mock transcribing audio (length: ${await audioFile.length()} bytes)');
    await Future.delayed(const Duration(milliseconds: 500));
    // Randomly return a close match for testing
    if (_random.nextDouble() > 0.3) {
      return 'بسم الله الرحمن الرحيم الحمد لله رب العالمين الرحمن الرحيم';
    } else {
      return 'بسم الله الرحمن';
    }
  }

  // Calculate similarity score between transcribed text and target verses (Levenshtein distance)
  double calculateSimilarity(String transcribedText, List<String> targetVerses) {
    String fullTargetText = targetVerses.join(' ');
    String normalizedTranscribed = _normalizeText(transcribedText);
    String normalizedTarget = _normalizeText(fullTargetText);
    
    int distance = _levenshteinDistance(normalizedTranscribed, normalizedTarget);
    int maxLength = normalizedTranscribed.length > normalizedTarget.length 
        ? normalizedTranscribed.length 
        : normalizedTarget.length;
    
    if (maxLength == 0) return 1.0;
    return 1.0 - (distance / maxLength);
  }

  // Levenshtein distance algorithm
  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<List<int>> matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  // Normalize text (remove harakat, punctuation, extra spaces, etc.)
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        // Remove harakat (tashkeel)
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '')
        // Remove punctuation
        .replaceAll(RegExp(r'[^\p{L}\s]', unicode: true), '')
        // Replace multiple spaces with single space
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // Dispose resources - no-op for mock
  void dispose() {}
}