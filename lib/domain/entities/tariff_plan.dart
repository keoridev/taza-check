import 'package:decimal/decimal.dart';

/// A mobile tariff plan offered by a Kyrgyz telecom operator.
class TariffPlan {
  const TariffPlan({
    required this.id,
    required this.operatorName,
    required this.name,
    required this.monthlyFeeSom,
    required this.includedMinutes,
    required this.includedGb,
    required this.includedSms,
    required this.overageMinuteSom,
    required this.overageGbSom,
    required this.overageSmsSom,
  });

  final String id;
  final String operatorName;
  final String name;
  final Decimal monthlyFeeSom;
  final int includedMinutes;
  final Decimal includedGb;
  final int includedSms;
  final Decimal overageMinuteSom;
  final Decimal overageGbSom;
  final Decimal overageSmsSom;
}

/// Evaluated recommendation comparing subscriber usage against a [TariffPlan].
class TariffRecommendation {
  const TariffRecommendation({
    required this.plan,
    required this.estimatedMonthlyCostSom,
    required this.monthlySavingsSom,
    required this.yearlySavingsSom,
    required this.fitsMinutes,
    required this.fitsData,
    required this.fitsSms,
  });

  final TariffPlan plan;
  final Decimal estimatedMonthlyCostSom;
  final Decimal monthlySavingsSom;
  final Decimal yearlySavingsSom;
  final bool fitsMinutes;
  final bool fitsData;
  final bool fitsSms;
}
