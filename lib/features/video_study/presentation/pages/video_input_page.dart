import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../domain/entities/video_resource.dart';
import '../providers/video_study_providers.dart';

class VideoInputPage extends ConsumerStatefulWidget {
  const VideoInputPage({super.key});

  @override
  ConsumerState<VideoInputPage> createState() => _VideoInputPageState();
}

class _VideoInputPageState extends ConsumerState<VideoInputPage> {
  final _urlController = TextEditingController();
  bool _isProcessing = false;
  String? _regeneratingVideoId;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _importVideo() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入 YouTube 视频链接')),
      );
      return;
    }

    // Basic YouTube URL validation.
    if (!url.contains('youtube.com') && !url.contains('youtu.be')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的 YouTube 链接')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Check for duplicate before full import.
      final videoId = VideoId(url);
      final repository = ref.read(videoStudyRepositoryProvider);
      final existing =
          await repository.getVideoResourceByYoutubeId(videoId.value);
      if (existing != null && mounted) {
        _urlController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('该视频已存在，已打开现有记录')),
        );
        context.go('/video-study/player/${existing.id}');
        return;
      }

      final processVideo = ref.read(processVideoUseCaseProvider);
      final videoResourceId = await processVideo(youtubeUrl: url);

      if (mounted) {
        _urlController.clear();
        ref.invalidate(videoResourcesListProvider);
        context.go('/video-study/player/$videoResourceId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<bool?> _confirmDeleteVideo(
      BuildContext context, VideoResource video) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除视频'),
        content: Text('确定要删除 "${video.title}" 吗？'),
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

  Future<void> _regenerateSubtitles(VideoResource video) async {
    if (_regeneratingVideoId != null) return;
    setState(() => _regeneratingVideoId = video.id);
    try {
      final useCase = ref.read(regenerateSubtitlesProvider);
      final success = await useCase(videoResource: video);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(success ? '字幕生成成功' : '字幕生成失败，请稍后重试')),
        );
        if (success) ref.invalidate(videoResourcesListProvider);
      }
    } finally {
      if (mounted) setState(() => _regeneratingVideoId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final videoResources = ref.watch(videoResourcesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('视频学习'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // URL input area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    hintText: '粘贴 YouTube 视频链接...',
                    prefixIcon: Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _importVideo,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download),
                    label: Text(_isProcessing ? '正在导入...' : '导入视频'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // History list header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('导入记录', style: theme.textTheme.headlineSmall),
                const Spacer(),
              ],
            ),
          ),
          // Video resources history list
          Expanded(
            child: videoResources.when(
              data: (videos) {
                if (videos.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.video_library_outlined,
                    title: '还没有导入记录',
                    subtitle: '粘贴 YouTube 链接开始学习吧',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    final hasSubtitles = video.segmentCount > 0;
                    return Dismissible(
                      key: ValueKey(video.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        color: theme.colorScheme.error,
                        child:
                            const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        final confirmed =
                            await _confirmDeleteVideo(context, video);
                        if (confirmed == true) {
                          ref
                              .read(videoResourcesListProvider.notifier)
                              .deleteVideo(video.id);
                        }
                        // Always return false — the item is removed via
                        // state update, not by Dismissible itself.
                        return false;
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: video.thumbnailUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    video.thumbnailUrl!,
                                    width: 80,
                                    height: 45,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 80,
                                      height: 45,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.video_library,
                                          size: 24),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 80,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.video_library,
                                      size: 24),
                                ),
                          title: Text(
                            video.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: hasSubtitles
                              ? Text(
                                  video.channelName ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : Row(
                                  children: [
                                    Icon(Icons.warning_amber,
                                        size: 14,
                                        color: theme.colorScheme.error),
                                    const SizedBox(width: 4),
                                    Text(
                                      '暂无字幕',
                                      style: TextStyle(
                                          color: theme.colorScheme.error),
                                    ),
                                  ],
                                ),
                          trailing: hasSubtitles
                              ? const Icon(Icons.chevron_right)
                              : _regeneratingVideoId == video.id
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.refresh),
                                      tooltip: '重新生成字幕',
                                      onPressed: _regeneratingVideoId != null
                                          ? null
                                          : () =>
                                              _regenerateSubtitles(video),
                                    ),
                          onTap: () =>
                              context.go('/video-study/player/${video.id}'),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const ShimmerLoading(itemCount: 3),
              error: (e, _) => ErrorRetryWidget(message: '加载失败: $e', onRetry: () => ref.invalidate(videoResourcesListProvider)),
            ),
          ),
        ],
      ),
    );
  }
}
