class AppConfig {
  static const String appName = 'Iqra';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.butterflydevs.iqc_iqra';
  
  // Firebase Configuration
  static const bool enableFirebase = true;
  
  // AI Verification Configuration
  static const double minVerificationScore = 0.7;
  static const int maxRecordingDuration = 300; // 5 minutes in seconds
  
  // Quran Configuration
  static const int dailyVerseTarget = 10;
  
  // Reward Configuration
  static const int pointsPerDay = 10;
  static const int streakBonusMultiplier = 2;
}
