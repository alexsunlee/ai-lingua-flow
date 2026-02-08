import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/widgets/interactive_text.dart';
import '../../../../core/widgets/word_card_popup.dart';
import '../../../../injection.dart';
import '../../../../services/dictionary_service.dart';
import '../../../../services/gemini_tts_service.dart';
import '../providers/text_study_providers.dart';

class TextReaderPage extends ConsumerStatefulWidget {
  final String studyTextId;

  const TextReaderPage({super.key, required this.studyTextId});

  @override
  ConsumerState<TextReaderPage> createState() => _TextReaderPageState();
}

class _TextReaderPageState extends ConsumerState<TextReaderPage> {
  final _vocabularyWords = <String>{};

  OverlayEntry? _activeOverlay;

  void _onWordTap(String word, Offset position) async {
    final dictService = getIt<DictionaryService>();
    final ttsService = getIt<GeminiTtsService>();

    // Dismiss any existing overlay
    _dismissOverlay();

    // Show loading card first
    _activeOverlay = WordCardPopup.showOverlay(
      context,
      position: position,
      data: WordCardData(word: word),
      isLoading: true,
    );

    try {
      final cardData = await dictService.lookup(word);

      if (mounted) {
        _dismissOverlay();
        _activeOverlay = WordCardPopup.showOverlay(
          context,
          position: position,
          data: cardData,
          onPlayTts: () => ttsService.speak(word),
          onAddToVocabulary: () {
            _addToVocabulary(cardData);
            _dismissOverlay();
          },
          onClose: _dismissOverlay,
        );
      }
    } catch (_) {
      if (mounted) {
        _dismissOverlay();
        _activeOverlay = WordCardPopup.showOverlay(
          context,
          position: position,
          data: WordCardData(word: word, explanation: '查询失败'),
          onClose: _dismissOverlay,
        );
      }
    }
  }

  void _dismissOverlay() {
    final overlay = _activeOverlay;
    _activeOverlay = null;
    if (overlay != null && overlay.mounted) {
      overlay.remove();
    }
  }

  void _addToVocabulary(WordCardData data) {
    ref.read(addToVocabularyProvider)(data);
    setState(() => _vocabularyWords.add(data.word.toLowerCase()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${data.word}" 已添加到生词本')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final studyText = ref.watch(studyTextDetailProvider(widget.studyTextId));

    return Scaffold(
      appBar: AppBar(
        title: studyText.when(
          data: (text) => Text(text?.title ?? '阅读'),
          loading: () => const Text('加载中...'),
          error: (_, _) => const Text('阅读'),
        ),
      ),
      body: studyText.when(
        data: (text) {
          if (text == null) {
            return const Center(child: Text('未找到文本'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Paragraphs with analysis
              if (text.paragraphs != null)
                ...text.paragraphs!.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final paragraph = entry.value;

                  // Parse knowledgeJson with backward compatibility
                  List<dynamic>? sentences;
                  List<dynamic>? keyPhrases;
                  bool isNewFormat = false;

                  if (paragraph.knowledgeJson != null) {
                    try {
                      final decoded = jsonDecode(paragraph.knowledgeJson!);
                      if (decoded is Map<String, dynamic>) {
                        // New format: {"sentences": [...], "key_phrases": [...]}
                        isNewFormat = true;
                        sentences = decoded['sentences'] as List<dynamic>?;
                        keyPhrases = decoded['key_phrases'] as List<dynamic>?;
                      } else if (decoded is List) {
                        // Old format: array of knowledge items
                        keyPhrases = decoded;
                      }
                    } catch (_) {
                      // Ignore parse errors
                    }
                  }

                  return Padding(
                    padding: EdgeInsets.only(top: idx == 0 ? 0 : 16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Paragraph header
                            Text(
                              '段落 ${idx + 1}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Original text (interactive)
                            InteractiveText(
                              text: paragraph.originalText,
                              onWordTap: _onWordTap,
                              highlightedWords: _vocabularyWords,
                            ),
                            // Sentence-by-sentence translations (new format)
                            if (isNewFormat && sentences != null && sentences.isNotEmpty) ...[
                              const Divider(height: 24),
                              Text(
                                '逐句翻译',
                                style: theme.textTheme.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              ...sentences.map((s) {
                                final sentence = s as Map<String, dynamic>;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sentence['original'] as String? ?? '',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        sentence['translation'] as String? ?? '',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            // Fallback: old translatedText
                            if (!isNewFormat && paragraph.translatedText != null) ...[
                              const Divider(height: 24),
                              Text(
                                paragraph.translatedText!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                            // Key phrases
                            if (keyPhrases != null && keyPhrases.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '重难点短语',
                                      style: theme.textTheme.labelLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    ...keyPhrases.map((k) {
                                      final item = k as Map<String, dynamic>;
                                      final phrase = item['phrase'] as String? ?? '';
                                      final explanation = item['explanation'] as String? ?? '';
                                      final pos = item['pos'] as String? ?? '';
                                      final difficulty = item['difficulty'] as String?;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: RichText(
                                                text: TextSpan(
                                                  style: theme.textTheme.bodySmall,
                                                  children: [
                                                    TextSpan(
                                                      text: phrase,
                                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                                    ),
                                                    if (pos.isNotEmpty)
                                                      TextSpan(
                                                        text: ' ($pos)',
                                                        style: TextStyle(
                                                          color: theme.colorScheme.outline,
                                                          fontStyle: FontStyle.italic,
                                                        ),
                                                      ),
                                                    TextSpan(text: ' — $explanation'),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (difficulty != null) ...[
                                              const SizedBox(width: 6),
                                              _DifficultyBadge(difficulty: difficulty),
                                            ],
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                            // Summary
                            if (paragraph.summary != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '要点总结',
                                      style: theme.textTheme.labelLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      paragraph.summary!,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
        loading: () => const ShimmerLoading.detail(),
        error: (e, _) => ErrorRetryWidget(message: '加载失败: $e', onRetry: () => ref.invalidate(studyTextDetailProvider(widget.studyTextId))),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final String difficulty;

  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (difficulty) {
      'beginner' => ('初级', Colors.green),
      'intermediate' => ('中级', Colors.orange),
      'advanced' => ('高级', Colors.red),
      _ => (difficulty, Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
