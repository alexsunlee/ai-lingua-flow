import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../injection.dart';
import '../../../../services/gemini_tts_service.dart';
import '../../domain/entities/vocabulary_entry.dart';
import '../providers/vocabulary_providers.dart';

/// Dictation practice page.
///
/// Plays audio of a word; the user types the spelling and checks correctness.
class DictationPage extends ConsumerStatefulWidget {
  const DictationPage({super.key});

  @override
  ConsumerState<DictationPage> createState() => _DictationPageState();
}

class _DictationPageState extends ConsumerState<DictationPage> {
  final _inputController = TextEditingController();
  final _focusNode = FocusNode();

  List<VocabularyEntry> _entries = [];
  int _currentIndex = 0;
  int _correctCount = 0;
  int _attemptedCount = 0;
  bool _hasChecked = false;
  bool _isCorrect = false;
  bool _isComplete = false;

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  VocabularyEntry? get _currentEntry =>
      _entries.isNotEmpty && _currentIndex < _entries.length
          ? _entries[_currentIndex]
          : null;

  void _initEntries(List<VocabularyEntry> entries) {
    if (_entries.isEmpty && entries.isNotEmpty) {
      setState(() {
        _entries = List.from(entries)..shuffle();
      });
      // Auto-play the first word
      WidgetsBinding.instance.addPostFrameCallback((_) => _playCurrentWord());
    }
  }

  void _playCurrentWord() {
    final entry = _currentEntry;
    if (entry != null) {
      final tts = getIt<GeminiTtsService>();
      tts.speak(entry.word);
    }
  }

  void _check() {
    final entry = _currentEntry;
    if (entry == null) return;

    final userInput = _inputController.text.trim().toLowerCase();
    final correctWord = entry.word.trim().toLowerCase();

    setState(() {
      _hasChecked = true;
      _isCorrect = userInput == correctWord;
      _attemptedCount++;
      if (_isCorrect) _correctCount++;
    });
  }

  void _next() {
    final nextIndex = _currentIndex + 1;
    if (nextIndex >= _entries.length) {
      setState(() => _isComplete = true);
      return;
    }

    setState(() {
      _currentIndex = nextIndex;
      _hasChecked = false;
      _isCorrect = false;
      _inputController.clear();
    });

    _focusNode.requestFocus();

    // Play the next word after a short delay
    Future.delayed(const Duration(milliseconds: 400), _playCurrentWord);
  }

  void _restart() {
    setState(() {
      _entries.shuffle();
      _currentIndex = 0;
      _correctCount = 0;
      _attemptedCount = 0;
      _hasChecked = false;
      _isCorrect = false;
      _isComplete = false;
      _inputController.clear();
    });
    _focusNode.requestFocus();
    Future.delayed(const Duration(milliseconds: 400), _playCurrentWord);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final vocabularyAsync = ref.watch(vocabularyListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('听写练习'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/review'),
        ),
      ),
      body: vocabularyAsync.when(
        data: (entries) {
          _initEntries(entries);

          if (_entries.isEmpty) {
            return const Center(child: Text('生词本为空，请先添加单词'));
          }

          if (_isComplete) {
            return _buildCompletionView(theme, colorScheme);
          }

          return _buildDictationView(theme, colorScheme);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('加载失败: $error')),
      ),
    );
  }

  Widget _buildDictationView(ThemeData theme, ColorScheme colorScheme) {
    final entry = _currentEntry;
    if (entry == null) return const SizedBox.shrink();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_currentIndex + 1} / ${_entries.length}',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  '正确: $_correctCount / $_attemptedCount',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _correctCount == _attemptedCount && _attemptedCount > 0
                        ? colorScheme.secondary
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _entries.length,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
            ),

            const Spacer(),

            // Play button
            GestureDetector(
              onTap: _playCurrentWord,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.volume_up,
                  size: 48,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击播放发音',
              style: theme.textTheme.bodySmall,
            ),

            const SizedBox(height: 32),

            // Input field
            TextField(
              controller: _inputController,
              focusNode: _focusNode,
              autofocus: true,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
              enabled: !_hasChecked,
              decoration: InputDecoration(
                hintText: '请输入听到的单词',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: _hasChecked
                    ? (_isCorrect
                        ? colorScheme.secondary.withValues(alpha: 0.1)
                        : colorScheme.error.withValues(alpha: 0.1))
                    : null,
              ),
              onSubmitted: (_) {
                if (!_hasChecked) _check();
              },
            ),

            const SizedBox(height: 16),

            // Feedback
            if (_hasChecked) ...[
              Icon(
                _isCorrect ? Icons.check_circle : Icons.cancel,
                color: _isCorrect ? colorScheme.secondary : colorScheme.error,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                _isCorrect ? '正确!' : '正确答案: ${entry.word}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color:
                      _isCorrect ? colorScheme.secondary : colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!_isCorrect && entry.translation != null) ...[
                const SizedBox(height: 4),
                Text(
                  entry.translation!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],

            const Spacer(),

            // Action buttons
            SizedBox(
              width: double.infinity,
              child: _hasChecked
                  ? ElevatedButton(
                      onPressed: _next,
                      child: Text(
                        _currentIndex + 1 >= _entries.length
                            ? '查看结果'
                            : '下一个',
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _inputController.text.trim().isNotEmpty
                          ? _check
                          : null,
                      child: const Text('检查'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionView(ThemeData theme, ColorScheme colorScheme) {
    final accuracy = _attemptedCount > 0
        ? (_correctCount / _attemptedCount * 100).round()
        : 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              accuracy >= 80
                  ? Icons.emoji_events
                  : accuracy >= 50
                      ? Icons.thumb_up
                      : Icons.refresh,
              size: 80,
              color: accuracy >= 80
                  ? Colors.amber
                  : accuracy >= 50
                      ? colorScheme.secondary
                      : colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              '听写完成!',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            Text(
              '正确率',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '$accuracy%',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontSize: 48,
                color: accuracy >= 80
                    ? colorScheme.secondary
                    : accuracy >= 50
                        ? colorScheme.primary
                        : colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_correctCount / $_attemptedCount',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: _restart,
                  child: const Text('再来一次'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => context.go('/review'),
                  child: const Text('返回生词本'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
