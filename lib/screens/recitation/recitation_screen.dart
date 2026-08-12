import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../../models/arabic_detection_result.dart';
import '../../services/permission_service.dart';
import '../../services/verification_service.dart';

class RecitationScreen extends StatefulWidget {
  const RecitationScreen({super.key});

  @override
  State<RecitationScreen> createState() => _RecitationScreenState();
}

class _RecitationScreenState extends State<RecitationScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final VerificationService _verificationService = VerificationService();

  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isVerifying = false;
  bool _isModelLoading = true;
  String? _recordingPath;
  String _verificationResult = '';
  double _arabicRatio = 0.0;
  String _detectedText = '';

  final List<Map<String, String>> _quranVerses = [
    {
      'arabic': 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
      'translation':
          'In the name of Allah, the Most Gracious, the Most Merciful',
      'transliteration': 'Bismillaahir Rahmaanir Raheem',
    },
    {
      'arabic': 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
      'translation': 'All praise is due to Allah, Lord of the worlds',
      'transliteration': 'Alhamdu lillaahi Rabbil \'aalameen',
    },
    {
      'arabic': 'الرَّحْمَنِ الرَّحِيمِ',
      'translation': 'The Most Gracious, the Most Merciful',
      'transliteration': 'Ar-Rahmaanir Raheem',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    _verificationService.dispose();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      await _verificationService.initModel();
      if (!mounted) return;
      setState(() => _isModelLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isModelLoading = false);
      _showError('Failed to load local Arabic detector: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      final bool hasPermission =
          await PermissionService.requestMicrophonePermission();
      if (!hasPermission) {
        _showError('Microphone permission is required for recording');
        return;
      }

      if (await _recorder.hasPermission()) {
        final Directory directory = Directory.systemTemp;
        final String path =
            '${directory.path}/recitation_${DateTime.now().millisecondsSinceEpoch}.wav';

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: path,
        );

        if (!mounted) return;
        setState(() {
          _isRecording = true;
          _recordingPath = path;
          _verificationResult = '';
          _arabicRatio = 0.0;
          _detectedText = '';
        });
      }
    } catch (e) {
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final String? path = await _recorder.stop();
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _recordingPath = path;
      });
    } catch (e) {
      _showError('Failed to stop recording: $e');
    }
  }

  Future<void> _playRecording() async {
    if (_recordingPath == null) return;

    try {
      await _player.play(DeviceFileSource(_recordingPath!));
      if (!mounted) return;
      setState(() => _isPlaying = true);

      _player.onPlayerComplete.first.then((_) {
        if (mounted) {
          setState(() => _isPlaying = false);
        }
      });
    } catch (e) {
      _showError('Failed to play recording: $e');
    }
  }

  Future<void> _verifyRecitation() async {
    if (_recordingPath == null) {
      _showError('Please record your recitation first');
      return;
    }

    setState(() {
      _isVerifying = true;
      _verificationResult = '';
    });

    try {
      final ArabicDetectionResult result =
          await _verificationService.detectArabic(File(_recordingPath!));

      final String resultText = result.isArabic
          ? '✅ Arabic speech detected. You can continue.'
          : '❌ Arabic speech was not detected confidently. Please recite again.';

      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _verificationResult = resultText;
        _arabicRatio = result.arabicRatio;
        _detectedText = result.transcribedText;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      _showError('Arabic detection failed: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quran Recitation'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isModelLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Preparing offline Arabic detector...'),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Today\'s Verses',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._quranVerses.asMap().entries.map((entry) {
                      final int index = entry.key;
                      final Map<String, String> verse = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${index + 1}. ${verse['arabic']}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                verse['transliteration'] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                verse['translation'] ?? '',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    const Text(
                      'Record Your Recitation',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The app only checks whether the recorded speech is Arabic. '
                      'It does not judge Tajweed or exact Ayah accuracy.',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isVerifying
                              ? null
                              : (_isRecording
                                  ? _stopRecording
                                  : _startRecording),
                          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                          label: Text(_isRecording ? 'Stop' : 'Record'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isRecording ? Colors.red : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                        if (_recordingPath != null && !_isRecording)
                          ElevatedButton.icon(
                            onPressed: _isPlaying || _isVerifying
                                ? null
                                : _playRecording,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isRecording)
                      Card(
                        color: Colors.red.shade50,
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.red),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Recording... Speak clearly for 2–5 seconds.'),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isVerifying || _isRecording
                          ? null
                          : _verifyRecitation,
                      icon: _isVerifying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.language),
                      label: Text(
                        _isVerifying
                            ? 'Detecting Arabic...'
                            : 'Check Arabic Language',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_verificationResult.isNotEmpty)
                      Card(
                        color: _verificationResult.startsWith('✅')
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _verificationResult,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _verificationResult.startsWith('✅')
                                      ? Colors.green.shade900
                                      : Colors.red.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Arabic-script evidence: ${(_arabicRatio * 100).toStringAsFixed(0)}%',
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: _arabicRatio,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _arabicRatio >= 0.60
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              if (_detectedText.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Text(
                                  'Local detector heard:',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _detectedText,
                                  textDirection: TextDirection.rtl,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
