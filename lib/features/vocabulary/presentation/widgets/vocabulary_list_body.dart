import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../injection.dart';
import '../../../../services/gemini_tts_service.dart';
import '../../domain/entities/vocabulary_entry.dart';
import '../providers/vocabulary_providers.dart';
import 'vocabulary_card.dart';

/// Extracted body content from VocabularyListPage for embedding in ReviewHubPage.
/// FAB is managed by the parent ReviewHubPage.
class VocabularyListBody extends ConsumerStatefulWidget {
  const VocabularyListBody({super.key});

  @override
  ConsumerState<VocabularyListBody> createState() => _VocabularyListBodyState();
}

class _VocabularyListBodyState extends ConsumerState<VocabularyListBody> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showDueOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final entriesAsync = _searchQuery.isNotEmpty
        ? ref.watch(vocabularySearchProvider(_searchQuery))
        : _showDueOnly
            ? ref.watch(dueReviewsProvider)
            : ref.watch(vocabularyListProvider);

    final dueCountAsync = ref.watch(dueReviewsProvider);
    final dueCount = dueCountAsync.valueOrNull?.length ?? 0;

    return Column(
      children: [
        // Action row: review badge + dictation button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              if (dueCount > 0)
                Badge(
                  label: Text('$dueCount'),
                  child: IconButton(
                    icon: const Icon(Icons.school),
                    tooltip: '开始复习',
                    onPressed: () => _startReviewSession(context),
                  ),
                ),
              const Spacer(),
            ],
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索单词或释义...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value.trim());
            },
          ),
        ),

        // Filter chips
        if (_searchQuery.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('全部'),
                  selected: !_showDueOnly,
                  onSelected: (_) => setState(() => _showDueOnly = false),
                  selectedColor: colorScheme.primary.withValues(alpha: 0.15),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text('待复习 ($dueCount)'),
                  selected: _showDueOnly,
                  onSelected: (_) => setState(() => _showDueOnly = true),
                  selectedColor: colorScheme.primary.withValues(alpha: 0.15),
                ),
              ],
            ),
          ),

        // Vocabulary list
        Expanded(
          child: entriesAsync.when(
            data: (entries) {
              if (entries.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.book_outlined,
                  title: _showDueOnly ? '没有待复习的单词' : '生词本为空',
                  subtitle: _showDueOnly ? null : '在阅读时长按单词即可添加',
                );
              }
              return _buildEntryList(entries);
            },
            loading: () => const ShimmerLoading(),
            error: (error, _) => ErrorRetryWidget(
              message: '加载失败: $error',
              onRetry: () => ref.invalidate(vocabularyListProvider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEntryList(List<VocabularyEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 80),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Dismissible(
          key: ValueKey(entry.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            color: Theme.of(context).colorScheme.error,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) => _confirmDelete(context, entry),
          onDismissed: (_) {
            ref.read(vocabularyListProvider.notifier).deleteEntry(entry.id);
          },
          child: VocabularyCard(
            entry: entry,
            onPlayAudio: () => _playWord(entry.word),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDelete(
      BuildContext context, VocabularyEntry entry) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除单词'),
        content: Text('确定要从生词本中删除 "${entry.word}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _startReviewSession(BuildContext context) {
    final dueEntries = ref.read(dueReviewsProvider).valueOrNull;
    if (dueEntries != null && dueEntries.isNotEmpty) {
      ref.read(reviewSessionProvider.notifier).startSession(dueEntries);
      context.go('/review/vocabulary/review');
    }
  }

  void _playWord(String word) {
    final tts = getIt<GeminiTtsService>();
    tts.speak(word);
  }
}
