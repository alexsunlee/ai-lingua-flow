import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/shadowing_providers.dart';

class ShadowingListPage extends ConsumerWidget {
  const ShadowingListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(shadowingSourcesProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('跟读练习'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => context.push('/settings'),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: '文本'),
              Tab(text: '视频'),
            ],
          ),
        ),
        body: sources.when(
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
                ),
                _SourceList(
                  sources: videoSources,
                  emptyMessage: '还没有视频材料\n请先在"视频学习"中添加视频',
                  emptyIcon: Icons.videocam_outlined,
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('加载失败: $e')),
        ),
      ),
    );
  }
}

class _SourceList extends StatelessWidget {
  final List<ShadowingSource> sources;
  final String emptyMessage;
  final IconData emptyIcon;

  const _SourceList({
    required this.sources,
    required this.emptyMessage,
    required this.emptyIcon,
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
          ],
        ),
      );
    }

    return ListView.builder(
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
              '/shadowing/practice/${source.id}?type=${source.type}',
            ),
          ),
        );
      },
    );
  }
}
