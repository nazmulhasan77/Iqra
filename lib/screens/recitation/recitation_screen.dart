import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import '../../services/permission_service.dart';
import '../../services/verification_service.dart';
import '../../services/recitation_service.dart';
import '../../models/recitation_submission.dart';
import 'package:uuid/uuid.dart';

class RecitationScreen extends StatefulWidget {
  const RecitationScreen({super.key});

  @override
  State<RecitationScreen> createState() => _RecitationScreenState();
}

class _RecitationScreenState extends State<RecitationScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final VerificationService _verificationService = VerificationService();
  final RecitationService _recitationService = RecitationService();
  final Uuid _uuid = const Uuid();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;
  String _verificationResult = '';
  bool _isVerifying = false;
  bool _isModelLoading = true;
  double _similarityScore = 0.0;

  // Sample Quran verses for demo
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
      setState(() => _isModelLoading = false);
    } catch (e) {
      _showError('Failed to load speech recognition model: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      // Check microphone permission
      final hasPermission =
          await PermissionService.requestMicrophonePermission();
      if (!hasPermission) {
        _showError('Microphone permission is required for recording');
        return;
      }

      if (await _recorder.hasPermission()) {
        final directory = Directory.systemTemp;
        final path =
            '${directory.path}/recitation_${DateTime.now().millisecondsSinceEpoch}.wav';

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _recordingPath = path;
          _verificationResult = '';
        });
      }
    } catch (e) {
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
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
      setState(() => _isPlaying = true);

      _player.onPlayerComplete.listen((_) {
        setState(() => _isPlaying = false);
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

    setState(() => _isVerifying = true);

    try {
      // Step 1: Get target verses text
      List<String> targetVerses = _quranVerses
          .map((v) => v['arabic']!)
          .toList();

      // Step 2: Transcribe audio (offline with Vosk)
      File audioFile = File(_recordingPath!);
      String transcribedText = await _verificationService.transcribeAudio(
        audioFile,
      );

      // Step 3: Calculate similarity score
      double similarityScore = _verificationService.calculateSimilarity(
        transcribedText,
        targetVerses,
      );

      // Step 4: Upload audio to Firebase Storage (replace 'test_user_id' with actual user ID later)
      String audioUrl = await _verificationService.uploadAudioToStorage(
        audioFile,
        'test_user_id',
      );

      // Step 5: Determine result based on score (threshold: 70%)
      bool isVerified = similarityScore >= 0.7;
      String resultText = isVerified
          ? '✅ Alhamdulillah! Your recitation has been verified successfully.\nScore: ${(similarityScore * 100).toStringAsFixed(1)}%'
          : '❌ Verification failed. Please try again.\nScore: ${(similarityScore * 100).toStringAsFixed(1)}%';

      // Step 6: Save submission to Firestore
      RecitationSubmission submission = RecitationSubmission(
        id: _uuid.v4(),
        assignmentId:
            'test_assignment_id', // Replace with actual assignment ID later
        audioUrl: audioUrl,
        submissionTime: DateTime.now(),
        verificationScore: similarityScore,
        verificationResult: isVerified ? 'success' : 'failed',
        retryNumber: 0,
        feedback: 'Transcribed: $transcribedText',
      );
      await _recitationService.submitRecitation(submission);

      setState(() {
        _isVerifying = false;
        _verificationResult = resultText;
        _similarityScore = similarityScore;
      });
    } catch (e) {
      setState(() => _isVerifying = false);
      _showError('Verification failed: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quran Recitation'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isModelLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Quran Verses Section
                    const Text(
                      'Today\'s Verses',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ..._quranVerses.asMap().entries.map((entry) {
                      final index = entry.key;
                      final verse = entry.value;
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
                    }).toList(),

                    const SizedBox(height: 24),

                    // Recording Section
                    const Text(
                      'Record Your Recitation',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Recording Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isRecording
                              ? _stopRecording
                              : _startRecording,
                          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                          label: Text(_isRecording ? 'Stop' : 'Record'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRecording
                                ? Colors.red
                                : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                        if (_recordingPath != null && !_isRecording)
                          ElevatedButton.icon(
                            onPressed: _isPlaying ? null : _playRecording,
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

                    // Recording Status
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.red,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Recording...'),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Verification Section
                    ElevatedButton.icon(
                      onPressed: _isVerifying ? null : _verifyRecitation,
                      icon: _isVerifying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.check_circle),
                      label: Text(
                        _isVerifying ? 'Verifying...' : 'Verify Recitation',
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

                    // Verification Result
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
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: _similarityScore,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _similarityScore >= 0.7
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
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
