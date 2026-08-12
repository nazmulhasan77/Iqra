class ArabicDetectionResult {
  final bool isArabic;
  final double arabicRatio;
  final String transcribedText;
  final int arabicCharacterCount;
  final int totalLetterCount;

  const ArabicDetectionResult({
    required this.isArabic,
    required this.arabicRatio,
    required this.transcribedText,
    required this.arabicCharacterCount,
    required this.totalLetterCount,
  });
}
