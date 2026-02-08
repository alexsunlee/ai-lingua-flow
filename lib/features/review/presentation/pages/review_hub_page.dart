import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../shadowing/presentation/providers/shadowing_providers.dart';
import '../../../vocabulary/presentation/providers/vocabulary_providers.dart';
import '../../../vocabulary/presentation/widgets/vocabulary_list_body.dart';

enum _ReviewView {
  vocabulary('单词本', Icons.book),
  vocabularyReview('单词复习', Icons.school),
  dictation('听写练习', Icons.edit_note),
  shadowingText('跟读文本练习', Icons.article),
  shadowingImage('跟读图片练习', Icons.image),
  shadowingVideo('跟读视频练习', Icons.videocam);

  const _ReviewView(this.label, this.icon);

  final String label;
  final IconData icon;
}

class ReviewHubPage extends ConsumerStatefulWidget {
  const ReviewHubPage({super.key});

  @override
  ConsumerState<ReviewHubPage> createState() => _ReviewHubPageState();
}

class _ReviewHubPageState extends ConsumerState<ReviewHubPage>
    with WidgetsBindingObserver {
  _ReviewView _currentView = _ReviewView.vocabulary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(shadowingSourcesProvider);
    }
  }

  void _onViewSelected(_ReviewView view) {
    if (view == _ReviewView.vocabularyReview) {
      _startVocabularyReview();
      return;
    }
    if (view == _ReviewView.dictation) {
      context.go('/review/vocabulary/dictation');
      return;
    }
    setState(() => _currentView = view);
  }

  void _startVocabularyReview() {
    final dueEntries = ref.read(dueReviewsProvider).valueOrNull;
    if (dueEntries != null && dueEntries.isNotEmpty) {
      ref.read(reviewSessionProvider.notifier).startSession(dueEntries);
      context.go('/review/vocabulary/review');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('目前没有待复习的单词')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dueCountAsync = ref.watch(dueReviewsProvider);
    final dueCount = dueCountAsync.valueOrNull?.length ?? 0;
    final showFab = _currentView == _ReviewView.vocabulary && dueCount > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentView.label),
        actions: [
          PopupMenuButton<_ReviewView>(
            icon: const Icon(Icons.arrow_drop_down),
            onSelected: _onViewSelected,
            itemBuilder: (context) => _ReviewView.values.map((view) {
              return PopupMenuItem<_ReviewView>(
                value: view,
                child: ListTile(
                  leading: Icon(view.icon),
                  title: Text(view.label),
                  selected: view == _currentView,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: _startVocabularyReview,
              icon: const Icon(Icons.school),
              label: Text('复习 ($dueCount)'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    switch (_currentView) {
      case _ReviewView.shadowingText:
        return _ShadowingFilteredList(
          filter: (s) =>
              s.type == 'text' && !s.title.startsWith('图片学习'),
          emptyMessage: '还没有文本材料\n请先在"文本学习"中添加文本',
          emptyIcon: Icons.article_outlined,
        );
      case _ReviewView.shadowingImage:
        return _ShadowingFilteredList(
          filter: (s) =>
              s.type == 'text' && s.title.startsWith('图片学习'),
          emptyMessage: '还没有图片学习材料\n请先在"图片学习"中拍照或选择图片',
          emptyIcon: Icons.image_outlined,
        );
      case _ReviewView.shadowingVideo:
        return _ShadowingFilteredList(
          filter: (s) => s.type == 'video',
          emptyMessage: '还没有视频材料\n请先在"视频学习"中添加视频',
          emptyIcon: Icons.videocam_outlined,
        );
      case _ReviewView.vocabulary:
        return const VocabularyListBody();
      case _ReviewView.vocabularyReview:
      case _ReviewView.dictation:
        // Should not reach here — handled in _onViewSelected
        return const SizedBox.shrink();
    }
  }
}

class _ShadowingFilteredList extends ConsumerWidget {
  final bool Function(ShadowingSource) filter;
  final String emptyMessage;
  final IconData emptyIcon;

  const _ShadowingFilteredList({
    required this.filter,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourcesAsync = ref.watch(shadowingSourcesProvider);
    final theme = Theme.of(context);

    return sourcesAsync.when(
      data: (allSources) {
        final sources = allSources.where(filter).toList();
        if (sources.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(emptyIcon, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.invalidate(shadowingSourcesProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('刷新'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(shadowingSourcesProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sources.length,
            itemBuilder: (context, index) {
              final source = sources[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    source.type == 'text'
                        ? (source.title.startsWith('图片学习')
                            ? Icons.image
                            : Icons.article)
                        : Icons.videocam,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(source.title),
                  subtitle: source.summary != null
                      ? Text(
                          source.summary!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text(
                          '${source.type == 'text' ? '文本' : '视频'} · '
                          '${source.createdAt.month}/${source.createdAt.day}',
                        ),
                  trailing: const Icon(Icons.play_arrow),
                  onTap: () => context.go(
                    '/review/shadowing/practice/${source.id}?type=${source.type}',
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const ShimmerLoading(),
      error: (e, _) => ErrorRetryWidget(
        message: '加载失败: $e',
        onRetry: () => ref.invalidate(shadowingSourcesProvider),
      ),
    );
  }
}
