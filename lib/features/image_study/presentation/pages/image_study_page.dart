import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/gemini_client.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../injection.dart';
import '../../../text_study/presentation/providers/text_study_providers.dart';

class ImageStudyPage extends ConsumerStatefulWidget {
  const ImageStudyPage({super.key});

  @override
  ConsumerState<ImageStudyPage> createState() => _ImageStudyPageState();
}

class _ImageStudyPageState extends ConsumerState<ImageStudyPage> {
  bool _isProcessingImage = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (image == null) return;

    await _processImage(image);
  }

  Future<void> _processImage(XFile image) async {
    setState(() => _isProcessingImage = true);

    try {
      final bytes = await File(image.path).readAsBytes();
      final mimeType = _inferMimeType(image.path);

      final gemini = getIt<GeminiClient>();
      final description = await gemini.generateTextFromImage(
        prompt:
            'Describe this image in English in detail. Write 2-3 paragraphs '
            'covering what you see, including objects, people, actions, colors, '
            'setting, and any text visible in the image.',
        imageBytes: bytes,
        mimeType: mimeType,
      );

      if (!mounted) return;

      final now = DateTime.now();
      final title = '图片学习 ${DateFormat('M/d').format(now)}';
      final analyzeText = ref.read(analyzeTextUseCaseProvider);
      final studyTextId =
          await analyzeText(title: title, text: description);

      if (mounted) {
        context.go('/image-study/reader/$studyTextId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('图片识别失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingImage = false);
    }
  }

  String _inferMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final studyTexts = ref.watch(studyTextsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('图片学习'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              // Entry buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    _EntryButton(
                      icon: Icons.photo_library,
                      label: '从相册选择',
                      onTap: _isProcessingImage
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                    ),
                    const SizedBox(width: 12),
                    _EntryButton(
                      icon: Icons.camera_alt,
                      label: '拍照',
                      onTap: _isProcessingImage
                          ? null
                          : () => _pickImage(ImageSource.camera),
                    ),
                  ],
                ),
              ),

              const Divider(height: 32),

              // History header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('学习记录', style: theme.textTheme.headlineSmall),
              ),

              // Image study history list (filter by title starting with "图片学习")
              studyTexts.when(
                data: (texts) {
                  final imageTexts = texts
                      .where((t) => t.title.startsWith('图片学习'))
                      .toList();
                  if (imageTexts.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 32),
                      child: EmptyStateWidget(
                        icon: Icons.image_outlined,
                        title: '还没有图片学习记录',
                        subtitle: '从相册选择或拍照开始学习吧',
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: imageTexts.length,
                    itemBuilder: (context, index) {
                      final text = imageTexts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            Icons.image,
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(
                            text.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            text.originalText.isNotEmpty
                                ? text.originalText
                                : '${text.createdAt.month}/${text.createdAt.day}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              context.go('/image-study/reader/${text.id}'),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: ShimmerLoading(itemCount: 3),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ErrorRetryWidget(
                    message: '加载失败: $e',
                    onRetry: () => ref.invalidate(studyTextsListProvider),
                  ),
                ),
              ),
            ],
          ),

          // Full-screen image processing overlay
          if (_isProcessingImage)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      '正在识别图片内容...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EntryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _EntryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Material(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(icon,
                    size: 28,
                    color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
