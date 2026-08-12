import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

import '../models/arabic_detection_result.dart';

class VerificationService {
  static const WhisperModel _model = WhisperModel.tiny;
  static const String _bundledModelAsset = 'lib/assets/models/ggml-tiny.bin';

  // The threshold is intentionally a little conservative. Whisper first
  // auto-detects the spoken language and produces text in that language.
  // We then check whether the detected transcript is predominantly Arabic
  // script. This is sufficient for the app's use-case: Arabic vs non-Arabic.
  static const double _arabicRatioThreshold = 0.60;
  static const int _minimumArabicCharacters = 4;
  static const int _minimumAudioBytes = 32000; // roughly 1 sec of 16 kHz mono PCM

  final WhisperController _controller = WhisperController();
  bool _initialized = false;

  /// Prepares Whisper Tiny for local inference.
  ///
  /// Preferred path: copy a bundled model from lib/assets/models/ggml-tiny.bin.
  /// If the asset is not bundled yet, whisper_ggml downloads the model once
  /// and caches it on the device. Audio recognition itself is always local.
  Future<void> initModel() async {
    if (_initialized) return;

    await _controller.initModel(_model);
    final String modelPath = await _controller.getPath(_model);
    final File modelFile = File(modelPath);

    if (!await modelFile.exists()) {
      final bool copied = await _copyBundledModel(modelFile);
      if (!copied) {
        await _controller.downloadModel(_model);
      }
    }

    if (!await modelFile.exists() || await modelFile.length() < 1000000) {
      throw Exception(
        'Whisper Tiny model is missing. Bundle $_bundledModelAsset for a fully '
        'offline first launch.',
      );
    }

    _initialized = true;
  }

  Future<bool> _copyBundledModel(File destination) async {
    try {
      final ByteData data = await rootBundle.load(_bundledModelAsset);
      await destination.parent.create(recursive: true);
      await destination.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Detects whether the recorded speech is Arabic.
  ///
  /// No audio is uploaded anywhere. Whisper runs on-device using the Tiny
  /// multilingual model with automatic language detection.
  Future<ArabicDetectionResult> detectArabic(File audioFile) async {
    if (!_initialized) {
      await initModel();
    }

    if (!await audioFile.exists()) {
      throw Exception('Recorded audio file was not found.');
    }

    final int audioBytes = await audioFile.length();
    if (audioBytes < _minimumAudioBytes) {
      throw Exception('Please record at least about 1 second of clear speech.');
    }

    final result = await _controller.transcribe(
      model: _model,
      audioPath: audioFile.path,
      lang: 'auto',
      noContext: true,
      suppressNonSpeechTokens: true,
      keepModelLoaded: true,
    );

    final String text = result?.transcription.text.trim() ?? '';
    if (text.isEmpty) {
      return const ArabicDetectionResult(
        isArabic: false,
        arabicRatio: 0.0,
        transcribedText: '',
        arabicCharacterCount: 0,
        totalLetterCount: 0,
      );
    }

    final _ScriptStats stats = _getScriptStats(text);
    final double ratio = stats.totalLetters == 0
        ? 0.0
        : stats.arabicLetters / stats.totalLetters;

    final bool isArabic =
        stats.arabicLetters >= _minimumArabicCharacters &&
        ratio >= _arabicRatioThreshold;

    return ArabicDetectionResult(
      isArabic: isArabic,
      arabicRatio: ratio.clamp(0.0, 1.0).toDouble(),
      transcribedText: text,
      arabicCharacterCount: stats.arabicLetters,
      totalLetterCount: stats.totalLetters,
    );
  }

  _ScriptStats _getScriptStats(String text) {
    int totalLetters = 0;
    int arabicLetters = 0;

    for (final int rune in text.runes) {
      if (_isIgnorableRune(rune)) continue;

      totalLetters++;
      if (_isArabicRune(rune)) {
        arabicLetters++;
      }
    }

    return _ScriptStats(
      totalLetters: totalLetters,
      arabicLetters: arabicLetters,
    );
  }

  bool _isIgnorableRune(int rune) {
    // Whitespace/control characters.
    if (rune <= 0x20) return true;

    // ASCII punctuation and digits.
    if ((rune >= 0x21 && rune <= 0x40) ||
        (rune >= 0x5B && rune <= 0x60) ||
        (rune >= 0x7B && rune <= 0x7E)) {
      return true;
    }

    // General punctuation.
    if (rune >= 0x2000 && rune <= 0x206F) return true;

    // Arabic-Indic / Extended Arabic-Indic digits.
    if ((rune >= 0x0660 && rune <= 0x0669) ||
        (rune >= 0x06F0 && rune <= 0x06F9)) {
      return true;
    }

    // Quranic/Arabic combining marks (harakat etc.) should not inflate the
    // Arabic ratio because they are not independent letters.
    if ((rune >= 0x064B && rune <= 0x065F) ||
        rune == 0x0670 ||
        (rune >= 0x06D6 && rune <= 0x06ED)) {
      return true;
    }

    return false;
  }

  bool _isArabicRune(int rune) {
    return (rune >= 0x0600 && rune <= 0x06FF) ||
        (rune >= 0x0750 && rune <= 0x077F) ||
        (rune >= 0x08A0 && rune <= 0x08FF) ||
        (rune >= 0xFB50 && rune <= 0xFDFF) ||
        (rune >= 0xFE70 && rune <= 0xFEFF);
  }

  void dispose() {
    unawaited(_controller.releaseModel());
  }
}

class _ScriptStats {
  final int totalLetters;
  final int arabicLetters;

  const _ScriptStats({
    required this.totalLetters,
    required this.arabicLetters,
  });
}
