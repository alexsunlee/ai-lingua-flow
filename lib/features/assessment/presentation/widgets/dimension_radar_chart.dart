import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Radar chart showing 4 skill dimensions: Reading, Listening, Speaking, Vocabulary.
class DimensionRadarChart extends StatelessWidget {
  final double reading;
  final double listening;
  final double speaking;
  final double vocabulary;

  const DimensionRadarChart({
    super.key,
    required this.reading,
    required this.listening,
    required this.speaking,
    required this.vocabulary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 250,
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              fillColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              borderColor: theme.colorScheme.primary,
              borderWidth: 2,
              entryRadius: 4,
              dataEntries: [
                RadarEntry(value: reading),
                RadarEntry(value: listening),
                RadarEntry(value: speaking),
                RadarEntry(value: vocabulary),
              ],
            ),
          ],
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: BorderSide(
            color: Colors.grey.shade300,
          ),
          titlePositionPercentageOffset: 0.2,
          titleTextStyle: theme.textTheme.bodySmall!.copyWith(
            fontWeight: FontWeight.w600,
          ),
          getTitle: (index, angle) {
            switch (index) {
              case 0:
                return RadarChartTitle(text: '阅读');
              case 1:
                return RadarChartTitle(text: '听力');
              case 2:
                return RadarChartTitle(text: '口语');
              case 3:
                return RadarChartTitle(text: '词汇');
              default:
                return const RadarChartTitle(text: '');
            }
          },
          tickCount: 4,
          ticksTextStyle: const TextStyle(
            color: Colors.transparent,
            fontSize: 10,
          ),
          tickBorderData: BorderSide(
            color: Colors.grey.shade200,
          ),
          radarShape: RadarShape.polygon,
        ),
      ),
    );
  }
}
