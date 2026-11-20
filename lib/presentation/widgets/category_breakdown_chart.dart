import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/decimal_utils.dart';
import '../../domain/entities/billing_record.dart';
import '../../domain/entities/financial_report.dart';
import '../theme/app_theme.dart';

/// Donut chart and legend displaying spend across all 5 billing categories.
class CategoryBreakdownChart extends StatelessWidget {
  const CategoryBreakdownChart({
    super.key,
    required this.report,
    required this.language,
  });

  final FinancialReport report;
  final AppLanguage language;

  static const Map<BillingType, Color> _categoryColors = <BillingType, Color>{
    BillingType.call: AppTheme.beelineYellow,
    BillingType.data: Color(0xFF38BDF8),
    BillingType.sms: Color(0xFFA855F7),
    BillingType.subscription: AppTheme.warmAmber,
    BillingType.content: AppTheme.coralRed,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = report.totalSpendSom;
    final nonZero = BillingType.values
        .where((t) => (report.byCategory[t] ?? Decimal.zero) > Decimal.zero)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 180,
          child: nonZero.isEmpty
              ? Center(
                  child: Text(
                    language == AppLanguage.ru
                        ? 'Нет расходов'
                        : 'Чыгымдар жок',
                  ),
                )
              : PieChart(
                  PieChartData(
                    centerSpaceRadius: 42,
                    sectionsSpace: 3,
                    sections: nonZero.map((type) {
                      final amount = report.byCategory[type] ?? Decimal.zero;
                      final pct = total > Decimal.zero
                          ? ((amount.toDouble() / total.toDouble()) * 100)
                          : 0.0;
                      final sliceColor = _categoryColors[type]!;
                      final useDarkText = type == BillingType.call;
                      return PieChartSectionData(
                        value: amount.toDouble(),
                        color: sliceColor,
                        radius: 42,
                        title: pct >= 7 ? '${pct.toStringAsFixed(0)}%' : '',
                        titleStyle: TextStyle(
                          color:
                              useDarkText ? AppTheme.obsidianBlack : Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      );
                    }).toList(),
                  ),
                  duration: Duration.zero,
                ),
        ),
        const SizedBox(height: 12),
        ...BillingType.values.map((type) {
          final amount = report.byCategory[type] ?? Decimal.zero;
          final pct = total > Decimal.zero
              ? ((amount.toDouble() / total.toDouble()) * 100)
              : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _categoryColors[type]!,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.categoryLabel(type, language),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  '${formatSom(amount)} сом (${pct.toStringAsFixed(1)}%)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
