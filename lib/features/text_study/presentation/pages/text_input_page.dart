import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../providers/text_study_providers.dart';

class TextInputPage extends ConsumerStatefulWidget {
  const TextInputPage({super.key});

  @override
  ConsumerState<TextInputPage> createState() => _TextInputPageState();
}

class _TextInputPageState extends ConsumerState<TextInputPage> {
  final _textController = TextEditingController();
  bool _isAnalyzing = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _analyzeText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入要学习的文本')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final title = '学习材料 ${DateTime.now().month}/${DateTime.now().day}';

      final analyzeText = ref.read(analyzeTextUseCaseProvider);
      final studyTextId = await analyzeText(
        title: title,
        text: text,
      );

      if (mounted) {
        ref.invalidate(studyTextsListProvider);
        context.go('/text-study/reader/$studyTextId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分析失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final studyTexts = ref.watch(studyTextsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('文本学习'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Input area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _textController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: '粘贴要学习的英文文本...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _analyzeText,
                    icon: _isAnalyzing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(_isAnalyzing ? '正在分析...' : 'AI 分析'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Study text history
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('学习记录', style: theme.textTheme.headlineSmall),
                const Spacer(),
              ],
            ),
          ),
          Expanded(
            child: studyTexts.when(
              data: (texts) {
                if (texts.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.article_outlined,
                    title: '还没有学习记录',
                    subtitle: '粘贴文本开始学习吧',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: texts.length,
                  itemBuilder: (context, index) {
                    final text = texts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(text.title),
                        subtitle: Text(
                          text.originalText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            context.go('/text-study/reader/${text.id}'),
                      ),
                    );
                  },
                );
              },
              loading: () => const ShimmerLoading(itemCount: 4),
              error: (e, _) => ErrorRetryWidget(
                message: '加载失败: $e',
                onRetry: () => ref.invalidate(studyTextsListProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
