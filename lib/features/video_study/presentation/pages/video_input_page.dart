import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/video_study_providers.dart';

class VideoInputPage extends ConsumerStatefulWidget {
  const VideoInputPage({super.key});

  @override
  ConsumerState<VideoInputPage> createState() => _VideoInputPageState();
}

class _VideoInputPageState extends ConsumerState<VideoInputPage> {
  final _urlController = TextEditingController();
  bool _isProcessing = false;

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
      final processVideo = ref.read(processVideoUseCaseProvider);
      final videoResourceId = await processVideo(youtubeUrl: url);

      if (mounted) {
        _urlController.clear();
        // Refresh the list.
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
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.video_library_outlined,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          '还没有导入记录\n粘贴 YouTube 链接开始学习吧',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    return Card(
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
                                child:
                                    const Icon(Icons.video_library, size: 24),
                              ),
                        title: Text(
                          video.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          video.channelName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            context.go('/video-study/player/${video.id}'),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
