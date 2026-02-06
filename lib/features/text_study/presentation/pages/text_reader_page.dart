import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/widgets/interactive_text.dart';
import '../../../../core/widgets/word_card_popup.dart';
import '../../../../injection.dart';
import '../../../../services/dictionary_service.dart';
import '../../../../services/tts_service.dart';
import '../providers/text_study_providers.dart';

class TextReaderPage extends ConsumerStatefulWidget {
  final String studyTextId;

  const TextReaderPage({super.key, required this.studyTextId});

  @override
  ConsumerState<TextReaderPage> createState() => _TextReaderPageState();
}

class _TextReaderPageState extends ConsumerState<TextReaderPage> {
  final _vocabularyWords = <String>{};

  void _onWordTap(String word, Offset position) async {
    final dictService = getIt<DictionaryService>();
    final ttsService = getIt<TtsService>();

    // Show loading card first
    WordCardPopup.show(
      context,
      position: position,
      data: WordCardData(word: word),
      isLoading: true,
    );

    try {
      final cardData = await dictService.lookup(word);

      if (mounted) {
        // Remove loading overlay and show full card
        // Navigator overlay handles this via new entry
        WordCardPopup.show(
          context,
          position: position,
          data: cardData,
          onPlayTts: () => ttsService.speak(word),
          onAddToVocabulary: () => _addToVocabulary(cardData),
        );
      }
    } catch (_) {
      if (mounted) {
        WordCardPopup.show(
          context,
          position: position,
          data: WordCardData(word: word, explanation: '查询失败'),
        );
      }
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
              // Original text with interactive words
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: InteractiveText(
                    text: text.originalText,
                    onWordTap: _onWordTap,
                    highlightedWords: _vocabularyWords,
                  ),
                ),
              ),

              // Paragraphs with analysis
              if (text.paragraphs != null)
                ...text.paragraphs!.map((paragraph) => Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InteractiveText(
                                text: paragraph.originalText,
                                onWordTap: _onWordTap,
                                highlightedWords: _vocabularyWords,
                              ),
                              if (paragraph.translatedText != null) ...[
                                const Divider(height: 24),
                                Text(
                                  paragraph.translatedText!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ],
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                    )),
            ],
          );
        },
        loading: () => const ShimmerLoading.detail(),
        error: (e, _) => ErrorRetryWidget(message: '加载失败: $e', onRetry: () => ref.invalidate(studyTextDetailProvider(widget.studyTextId))),
      ),
    );
  }
}
