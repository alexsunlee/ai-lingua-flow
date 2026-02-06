import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../providers/assessment_providers.dart';
import '../widgets/dimension_radar_chart.dart';
import '../widgets/stats_card.dart';

class AssessmentPage extends ConsumerStatefulWidget {
  const AssessmentPage({super.key});

  @override
  ConsumerState<AssessmentPage> createState() => _AssessmentPageState();
}

class _AssessmentPageState extends ConsumerState<AssessmentPage> {
  bool _isGenerating = false;

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);
    try {
      final generateAssessment = ref.read(generateAssessmentProvider);
      final now = DateTime.now();
      await generateAssessment.call(
        start: now.subtract(const Duration(days: 7)),
        end: now,
        reportType: 'weekly',
      );
      ref.invalidate(assessmentReportsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('评估报告已生成')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = ref.watch(learningStatsProvider);
    final reports = ref.watch(assessmentReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('学习评估'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats cards
          stats.when(
            data: (s) => Row(
              children: [
                Expanded(
                  child: StatsCard(
                    icon: Icons.timer,
                    label: '学习时间(分)',
                    value: '${s.totalStudyMinutes}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatsCard(
                    icon: Icons.book,
                    label: '新学单词',
                    value: '${s.wordsLearned}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatsCard(
                    icon: Icons.check_circle,
                    label: '学习次数',
                    value: '${s.sessionsCompleted}',
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox(
              height: 100,
              child: ShimmerLoading(itemCount: 1),
            ),
            error: (e, _) => ErrorRetryWidget(message: '加载统计失败: $e', onRetry: () => ref.invalidate(learningStatsProvider)),
          ),

          const SizedBox(height: 16),

          // Generate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateReport,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isGenerating ? '正在生成...' : '生成评估报告'),
            ),
          ),

          const SizedBox(height: 24),

          // Reports
          reports.when(
            data: (reportList) {
              if (reportList.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.assessment_outlined,
                  title: '还没有评估报告',
                  subtitle: '完成一些学习后生成你的第一份报告',
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('最新报告', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 12),

                  // Latest report detail
                  _buildReportDetail(context, reportList.first),

                  if (reportList.length > 1) ...[
                    const SizedBox(height: 24),
                    Text('历史报告', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    ...reportList.skip(1).map((report) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              '${report.reportType == 'weekly' ? '周报' : '月报'} '
                              '${report.periodStart.month}/${report.periodStart.day}'
                              ' - ${report.periodEnd.month}/${report.periodEnd.day}',
                            ),
                            subtitle: report.overallScore != null
                                ? Text(
                                    '综合评分: ${report.overallScore!.toStringAsFixed(0)}')
                                : null,
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        )),
                  ],
                ],
              );
            },
            loading: () => const ShimmerLoading(itemCount: 2),
            error: (e, _) => ErrorRetryWidget(message: '加载报告失败: $e', onRetry: () => ref.invalidate(assessmentReportsProvider)),
          ),
        ],
      ),
    );
  }

  Widget _buildReportDetail(
      BuildContext context, dynamic report) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall score
            if (report.overallScore != null)
              Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: report.overallScore! / 100,
                            strokeWidth: 8,
                            backgroundColor: Colors.grey.shade200,
                          ),
                          Text(
                            '${report.overallScore!.toStringAsFixed(0)}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('综合评分', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),

            // Radar chart
            if (report.dimensionsJson != null) ...[
              const SizedBox(height: 16),
              DimensionRadarChart(
                reading:
                    (report.dimensionsJson!['reading'] as num?)?.toDouble() ??
                        0,
                listening:
                    (report.dimensionsJson!['listening'] as num?)?.toDouble() ??
                        0,
                speaking:
                    (report.dimensionsJson!['speaking'] as num?)?.toDouble() ??
                        0,
                vocabulary:
                    (report.dimensionsJson!['vocabulary'] as num?)?.toDouble() ??
                        0,
              ),
            ],

            // Summary
            if (report.summaryText != null) ...[
              const SizedBox(height: 16),
              Text('AI 评估', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(report.summaryText!, style: theme.textTheme.bodyMedium),
            ],

            // Recommendations
            if (report.recommendations != null &&
                report.recommendations!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('建议', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              ...report.recommendations!.map(
                (rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 16, color: theme.colorScheme.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child:
                            Text(rec, style: theme.textTheme.bodySmall),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
