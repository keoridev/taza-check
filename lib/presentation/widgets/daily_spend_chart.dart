import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/decimal_utils.dart';
import '../../domain/entities/anomaly.dart';
import '../../domain/entities/financial_report.dart';
import '../theme/app_theme.dart';

/// Interactive daily spend bar chart: normal days in Beeline Yellow (`#FFCC00`)
/// and `day_spike` anomaly days highlighted in glowing Coral Red (`#FF3B30`).
class DailySpendChart extends StatelessWidget {
  const DailySpendChart({
    super.key,
    required this.days,
    required this.anomalies,
    required this.language,
  });

  final List<DailySpend> days;
  final List<Anomaly> anomalies;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spikeByDate = <String, Anomaly>{
      for (final a in anomalies)
        if (a.type == AnomalyType.daySpike) a.datetime: a,
    };

    if (days.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            AppStrings.tr(
              language,
              ru: 'Нет данных по дням',
              ky: 'Күндүк маалымат жок',
              en: 'No daily spend data',
            ),
          ),
        ),
      );
    }

    var maxSpend = 10.0;
    for (final d in days) {
      maxSpend = math.max(maxSpend, d.totalSom.toDouble());
    }
    final chartMaxY = (maxSpend * 1.18).ceilToDouble();

    final isNarrow = MediaQuery.sizeOf(context).width < 600;
    final barWidth = days.length > 24 ? (isNarrow ? 5.5 : 7.5) : 12.0;
    final labelStep = isNarrow
        ? (days.length > 20 ? 7 : 4)
        : (days.length > 20 ? 5 : (days.length > 10 ? 3 : 1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _LegendDot(
              color: AppTheme.beelineYellow,
              label: AppStrings.tr(
                language,
                ru: 'Обычный день',
                ky: 'Кадимки күн',
                en: 'Normal day',
              ),
            ),
            _LegendDot(
              color: AppTheme.coralRed,
              label: AppStrings.tr(
                language,
                ru: 'Всплеск (z > 3)',
                ky: 'Кескин өсүш (z > 3)',
                en: 'Spike (z > 3)',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: isNarrow ? 190 : 240,
          child: BarChart(
            BarChartData(
              maxY: chartMaxY,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  strokeWidth: 1,
                  dashArray: const [4, 4],
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (value, meta) {
                      if (value == 0 || value == meta.max) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        space: 6,
                        child: Text(
                          value.toInt().toString(),
                          style: theme.textTheme.labelSmall,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= days.length) {
                        return const SizedBox.shrink();
                      }
                      // Hide second-to-last (and adjacent) labels so they never
                      // collide with the final day label (e.g. 09-29 vs 09-30).
                      if (idx != days.length - 1 &&
                          (days.length - 1 - idx) <= 2) {
                        return const SizedBox.shrink();
                      }
                      if (idx % labelStep != 0 && idx != days.length - 1) {
                        return const SizedBox.shrink();
                      }
                      final shortDate = days[idx].date.substring(5);
                      return SideTitleWidget(
                        meta: meta,
                        space: 6,
                        child: Text(
                          shortDate,
                          style: theme.textTheme.labelSmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppTheme.carbonElevated,
                  tooltipBorder: const BorderSide(
                    color: AppTheme.beelineYellow,
                    width: 1,
                  ),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final day = days[group.x];
                    final spike = spikeByDate[day.date];
                    final som = formatSom(day.totalSom);
                    final zText = spike?.zScore != null
                        ? '\n⚠ day_spike (z=${spike!.zScore!.toStringAsFixed(1)})'
                        : '';
                    return BarTooltipItem(
                      '${day.date}\n$som сом$zText',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              barGroups: List<BarChartGroupData>.generate(days.length, (index) {
                final day = days[index];
                final isSpike = spikeByDate.containsKey(day.date);
                return BarChartGroupData(
                  x: index,
                  barRods: <BarChartRodData>[
                    BarChartRodData(
                      toY: day.totalSom.toDouble(),
                      width: barWidth,
                      gradient: isSpike
                          ? const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                AppTheme.coralRed,
                                Color(0xFFFF6E66),
                              ],
                            )
                          : null,
                      color: isSpike ? null : AppTheme.beelineYellow,
                      borderSide: isSpike
                          ? BorderSide(
                              color: AppTheme.coralRed.withValues(alpha: 0.45),
                              width: 2,
                            )
                          : BorderSide.none,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ],
                );
              }),
            ),
            duration: Duration.zero,
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
