import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/widgets/interactive_text.dart';
import '../../../../core/widgets/word_card_popup.dart';
import '../../../../injection.dart';
import '../../../../services/dictionary_service.dart';
import '../../../../services/tts_service.dart';
import '../providers/video_study_providers.dart';

class VideoPlayerPage extends ConsumerStatefulWidget {
  final String videoResourceId;

  const VideoPlayerPage({super.key, required this.videoResourceId});

  @override
  ConsumerState<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends ConsumerState<VideoPlayerPage> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  int _activeSegmentIndex = -1;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initVideo(String url) {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoController!,
            autoPlay: false,
            aspectRatio: 16 / 9,
          );
        });

        // Position listener for transcript sync
        _videoController!.addListener(_onPositionChanged);
      });
  }

  void _onPositionChanged() {
    final video = ref.read(videoResourceDetailProvider(widget.videoResourceId));
    video.whenData((resource) {
      if (resource?.segments == null) return;
      final posMs = _videoController!.value.position.inMilliseconds;
      final segments = resource!.segments!;

      for (int i = 0; i < segments.length; i++) {
        if (posMs >= segments[i].startMs && posMs < segments[i].endMs) {
          if (i != _activeSegmentIndex) {
            setState(() => _activeSegmentIndex = i);
            _scrollToSegment(i);
          }
          break;
        }
      }
    });
  }

  void _scrollToSegment(int index) {
    final offset = index * 80.0; // approximate height per segment
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _seekToSegment(int startMs) {
    _videoController?.seekTo(Duration(milliseconds: startMs));
    if (_videoController != null && !_videoController!.value.isPlaying) {
      _videoController!.play();
    }
  }

  void _onWordTap(String word, Offset position) async {
    final dictService = getIt<DictionaryService>();
    final ttsService = getIt<TtsService>();

    WordCardPopup.show(
      context,
      position: position,
      data: WordCardData(word: word),
      isLoading: true,
    );

    try {
      final cardData = await dictService.lookup(word);
      if (mounted) {
        WordCardPopup.show(
          context,
          position: position,
          data: cardData,
          onPlayTts: () => ttsService.speak(word),
          onAddToVocabulary: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('"${cardData.word}" 已添加到生词本')),
            );
          },
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final video = ref.watch(videoResourceDetailProvider(widget.videoResourceId));

    return Scaffold(
      appBar: AppBar(title: const Text('视频学习')),
      body: video.when(
        data: (resource) {
          if (resource == null) {
            return const Center(child: Text('未找到视频'));
          }

          // Initialize video controller if needed
          if (_videoController == null) {
            // Use youtube URL for now — real implementation would use extracted stream URL
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (resource.audioFilePath != null) {
                _initVideo(resource.audioFilePath!);
              }
            });
          }

          return Column(
            children: [
              // Video player
              AspectRatio(
                aspectRatio: 16 / 9,
                child: _chewieController != null
                    ? Chewie(controller: _chewieController!)
                    : Container(
                        color: Colors.black,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
              ),

              // Transcript header
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Text('字幕', style: theme.textTheme.headlineSmall),
                    const Spacer(),
                    Text(
                      '${resource.segments?.length ?? 0} 段',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // Scrollable transcript
              Expanded(
                child: resource.segments == null || resource.segments!.isEmpty
                    ? Center(
                        child: Text('暂无字幕',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey)),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: resource.segments!.length,
                        itemBuilder: (context, index) {
                          final segment = resource.segments![index];
                          final isActive = index == _activeSegmentIndex;

                          return GestureDetector(
                            onTap: () => _seekToSegment(segment.startMs),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? theme.colorScheme.primary
                                        .withValues(alpha: 0.1)
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                                border: isActive
                                    ? Border.all(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.3))
                                    : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatMs(segment.startMs),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: isActive
                                          ? FontWeight.bold
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  InteractiveText(
                                    text: segment.originalText,
                                    onWordTap: _onWordTap,
                                  ),
                                  if (segment.translatedText != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      segment.translatedText!,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.secondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const ShimmerLoading.detail(),
        error: (e, _) => ErrorRetryWidget(message: '加载失败: $e', onRetry: () => ref.invalidate(videoResourceDetailProvider(widget.videoResourceId))),
      ),
    );
  }

  String _formatMs(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
