import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/widgets/interactive_text.dart';
import '../../../../injection.dart';
import '../../../../services/tts_service.dart';
import '../../domain/usecases/compare_pronunciation.dart';
import '../widgets/pronunciation_feedback_widget.dart';

class ShadowingPracticePage extends ConsumerStatefulWidget {
  final String sourceId;
  final String sourceType;

  const ShadowingPracticePage({
    super.key,
    required this.sourceId,
    required this.sourceType,
  });

  @override
  ConsumerState<ShadowingPracticePage> createState() =>
      _ShadowingPracticePageState();
}

class _ShadowingPracticePageState
    extends ConsumerState<ShadowingPracticePage> {
  final _stt = SpeechToText();
  final _ttsService = getIt<TtsService>();
  final _comparePronunciation = ComparePronunciation();

  List<String> _sentences = [];
  int _currentIndex = 0;
  bool _isListening = false;
  bool _isListeningMode = false; // false = reading mode, true = listening mode
  String _recognizedText = '';
  PronunciationResult? _result;
  double _speechRate = 1.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSentences();
    _initStt();
  }

  Future<void> _initStt() async {
    await _stt.initialize();
  }

  Future<void> _loadSentences() async {
    final db = await AppDatabase.database;

    if (widget.sourceType == 'text') {
      final paragraphs = await db.query(
        'paragraphs',
        where: 'study_text_id = ?',
        whereArgs: [widget.sourceId],
        orderBy: 'paragraph_index ASC',
      );
      _sentences = paragraphs
          .map((p) => p['original_text'] as String)
          .expand((text) => text.split(RegExp(r'[.!?]+\s*')))
          .where((s) => s.trim().isNotEmpty)
          .toList();
    } else {
      final segments = await db.query(
        'transcript_segments',
        where: 'video_resource_id = ?',
        whereArgs: [widget.sourceId],
        orderBy: 'segment_index ASC',
      );
      _sentences =
          segments.map((s) => s['original_text'] as String).toList();
    }

    if (_sentences.isEmpty) {
      // Fallback: load from study_texts directly
      final texts = await db.query(
        'study_texts',
        where: 'id = ?',
        whereArgs: [widget.sourceId],
        limit: 1,
      );
      if (texts.isNotEmpty) {
        final text = texts.first['original_text'] as String;
        _sentences = text
            .split(RegExp(r'[.!?]+\s*'))
            .where((s) => s.trim().isNotEmpty)
            .toList();
      }
    }

    setState(() => _loading = false);
  }

  String get _currentSentence =>
      _sentences.isNotEmpty ? _sentences[_currentIndex] : '';

  Future<void> _playReference() async {
    await _ttsService.setSpeechRate(_speechRate * 0.45);
    await _ttsService.speak(_currentSentence);
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _recognizedText = '';
      _result = null;
    });

    await _stt.listen(
      onResult: (result) {
        setState(() {
          _recognizedText = result.recognizedWords;
        });
        if (result.finalResult) {
          _stopListening();
        }
      },
      localeId: 'en_US',
    );
  }

  Future<void> _stopListening() async {
    await _stt.stop();
    setState(() => _isListening = false);

    if (_recognizedText.isNotEmpty) {
      final result = await _comparePronunciation.call(
        referenceText: _currentSentence,
        recognizedText: _recognizedText,
      );
      setState(() => _result = result);

      // Save session
      final db = await AppDatabase.database;
      await db.insert('shadowing_sessions', {
        'id': const Uuid().v4(),
        'source_type': widget.sourceType,
        'source_id': widget.sourceId,
        'sentence_text': _currentSentence,
        'sentence_index': _currentIndex,
        'recognized_text': _recognizedText,
        'pronunciation_score': result.score,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  void _goToSentence(int index) {
    if (index < 0 || index >= _sentences.length) return;
    setState(() {
      _currentIndex = index;
      _recognizedText = '';
      _result = null;
    });
  }

  @override
  void dispose() {
    _stt.stop();
    _ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('跟读练习')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_sentences.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('跟读练习')),
        body: const Center(child: Text('没有可练习的句子')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1} / ${_sentences.length}'),
        actions: [
          // Mode toggle
          IconButton(
            icon: Icon(
              _isListeningMode ? Icons.hearing : Icons.visibility,
            ),
            tooltip: _isListeningMode ? '听力模式' : '阅读模式',
            onPressed: () =>
                setState(() => _isListeningMode = !_isListeningMode),
          ),
          // Speed control
          PopupMenuButton<double>(
            icon: const Icon(Icons.speed),
            onSelected: (speed) => setState(() => _speechRate = speed),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 0.5, child: Text('0.5x')),
              const PopupMenuItem(value: 0.75, child: Text('0.75x')),
              const PopupMenuItem(value: 1.0, child: Text('1.0x')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _sentences.length,
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(height: 24),

            // Current sentence
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (!_isListeningMode)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: InteractiveText(
                            text: _currentSentence,
                            style: theme.textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(Icons.hearing,
                                  size: 48, color: theme.colorScheme.primary),
                              const SizedBox(height: 8),
                              Text('听力模式 - 点击播放',
                                  style: theme.textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Recognized text
                    if (_recognizedText.isNotEmpty) ...[
                      Card(
                        color: Colors.grey.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('你说的:', style: theme.textTheme.labelLarge),
                              const SizedBox(height: 8),
                              Text(
                                _recognizedText,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Pronunciation feedback
                    if (_result != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Score
                              Text(
                                '${_result!.score.toStringAsFixed(0)} 分',
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  color: _result!.score >= 80
                                      ? Colors.green
                                      : _result!.score >= 60
                                          ? Colors.orange
                                          : Colors.red,
                                ),
                              ),
                              const SizedBox(height: 12),
                              PronunciationFeedbackWidget(
                                referenceText: _currentSentence,
                                recognizedText: _recognizedText,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Controls
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Previous
                IconButton.outlined(
                  onPressed: _currentIndex > 0
                      ? () => _goToSentence(_currentIndex - 1)
                      : null,
                  icon: const Icon(Icons.skip_previous),
                ),
                // Play reference
                IconButton.filled(
                  onPressed: _playReference,
                  icon: const Icon(Icons.volume_up),
                  iconSize: 32,
                ),
                // Record
                GestureDetector(
                  onLongPressStart: (_) => _startListening(),
                  onLongPressEnd: (_) => _stopListening(),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening
                          ? Colors.red
                          : theme.colorScheme.primary,
                    ),
                    child: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                // Next
                IconButton.outlined(
                  onPressed: _currentIndex < _sentences.length - 1
                      ? () => _goToSentence(_currentIndex + 1)
                      : null,
                  icon: const Icon(Icons.skip_next),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '长按麦克风录音',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
