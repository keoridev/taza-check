import 'package:decimal/decimal.dart';

import '../../domain/entities/financial_report.dart';
import '../../domain/entities/tariff_plan.dart';
import '../constants/tariff_catalog.dart';
import '../utils/decimal_utils.dart';

/// Compares actual subscriber consumption against Kyrgyz mobile operator plans.
class TariffOptimizer {
  static final Decimal _thirty = Decimal.fromInt(30);
  static final Decimal _twelve = Decimal.fromInt(12);
  static final Decimal _kbInGb = Decimal.fromInt(1024);

  /// Evaluates all plans in [catalog] (defaults to [defaultKyrgyzTariffs])
  /// and sorts recommendations by lowest estimated monthly cost.
  List<TariffRecommendation> optimize(
    FinancialReport report, {
    List<TariffPlan>? catalog,
  }) {
    final plans = catalog ?? defaultKyrgyzTariffs;
    final periodDays = report.periodDays > 0 ? report.periodDays : 30;
    final daysDec = Decimal.fromInt(periodDays);

    final monthlyMinutes = divToDecimal(
      report.totalCallMinutes * _thirty,
      daysDec,
      scale: 2,
    );
    final monthlyGb = divToDecimal(
      report.totalDataMb * _thirty,
      daysDec * _kbInGb,
      scale: 2,
    );
    final monthlySms = divToDecimal(
      Decimal.fromInt(report.totalSmsCount) * _thirty,
      daysDec,
      scale: 2,
    );
    final currentMonthlySpend = divToDecimal(
      report.totalSpendSom * _thirty,
      daysDec,
      scale: 2,
    ).round(scale: 2);

    final recommendations = <TariffRecommendation>[];
    for (final plan in plans) {
      final incMin = Decimal.fromInt(plan.includedMinutes);
      final incSms = Decimal.fromInt(plan.includedSms);

      final extraMin =
          monthlyMinutes > incMin ? monthlyMinutes - incMin : Decimal.zero;
      final extraGb =
          monthlyGb > plan.includedGb ? monthlyGb - plan.includedGb : Decimal.zero;
      final extraSms =
          monthlySms > incSms ? monthlySms - incSms : Decimal.zero;

      final estimatedMonthly = (plan.monthlyFeeSom +
              extraMin * plan.overageMinuteSom +
              extraGb * plan.overageGbSom +
              extraSms * plan.overageSmsSom)
          .round(scale: 2);

      final monthlySavings = currentMonthlySpend > estimatedMonthly
          ? (currentMonthlySpend - estimatedMonthly).round(scale: 2)
          : Decimal.zero;
      final yearlySavings = (monthlySavings * _twelve).round(scale: 2);

      recommendations.add(
        TariffRecommendation(
          plan: plan,
          estimatedMonthlyCostSom: estimatedMonthly,
          monthlySavingsSom: monthlySavings,
          yearlySavingsSom: yearlySavings,
          fitsMinutes: monthlyMinutes <= incMin,
          fitsData: monthlyGb <= plan.includedGb,
          fitsSms: monthlySms <= incSms,
        ),
      );
    }

    recommendations.sort((a, b) {
      final costCmp =
          a.estimatedMonthlyCostSom.compareTo(b.estimatedMonthlyCostSom);
      if (costCmp != 0) return costCmp;
      return a.plan.name.compareTo(b.plan.name);
    });

    return recommendations;
  }
}
