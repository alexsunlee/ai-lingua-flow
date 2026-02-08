import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../providers/shadowing_providers.dart';

/// Extracted body content from ShadowingListPage for embedding in ReviewHubPage.
class ShadowingListBody extends ConsumerStatefulWidget {
  const ShadowingListBody({super.key});

  @override
  ConsumerState<ShadowingListBody> createState() => _ShadowingListBodyState();
}

class _ShadowingListBodyState extends ConsumerState<ShadowingListBody>
    with WidgetsBindingObserver {
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.invalidate(shadowingSourcesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final sources = ref.watch(shadowingSourcesProvider);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: '文本'),
              Tab(text: '视频'),
            ],
          ),
          Expanded(
            child: sources.when(
              data: (sourceList) {
                final textSources =
                    sourceList.where((s) => s.type == 'text').toList();
                final videoSources =
                    sourceList.where((s) => s.type == 'video').toList();

                return TabBarView(
                  children: [
                    _SourceList(
                      sources: textSources,
                      emptyMessage: '还没有文本材料\n请先在"文本学习"中添加文本',
                      emptyIcon: Icons.article_outlined,
                      onRefresh: () =>
                          ref.invalidate(shadowingSourcesProvider),
                    ),
                    _SourceList(
                      sources: videoSources,
                      emptyMessage: '还没有视频材料\n请先在"视频学习"中添加视频',
                      emptyIcon: Icons.videocam_outlined,
                      onRefresh: () =>
                          ref.invalidate(shadowingSourcesProvider),
                    ),
                  ],
                );
              },
              loading: () => const ShimmerLoading(),
              error: (e, _) => ErrorRetryWidget(
                message: '加载失败: $e',
                onRetry: () => ref.invalidate(shadowingSourcesProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceList extends StatelessWidget {
  final List<ShadowingSource> sources;
  final String emptyMessage;
  final IconData emptyIcon;
  final VoidCallback onRefresh;

  const _SourceList({
    required this.sources,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('刷新'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sources.length,
        itemBuilder: (context, index) {
          final source = sources[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                source.type == 'text' ? Icons.article : Icons.videocam,
                color: theme.colorScheme.primary,
              ),
              title: Text(source.title),
              subtitle: Text(
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
  }
}
