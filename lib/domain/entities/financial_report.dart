import 'package:decimal/decimal.dart';

import 'billing_record.dart';

/// Spend summary for a single calendar day.
class DailySpend {
  const DailySpend({
    required this.date,
    required this.utcDate,
    required this.totalSom,
    required this.recordCount,
  });

  final String date;
  final DateTime utcDate;
  final Decimal totalSom;
  final int recordCount;
}

/// Aggregated spend associated with a normalized recipient number.
class NumberSpend {
  const NumberSpend({
    required this.normalizedNumber,
    required this.totalSom,
    required this.count,
    required this.isShortCode,
  });

  final String normalizedNumber;
  final Decimal totalSom;
  final int count;
  final bool isShortCode;
}

/// Aggregated financial metrics across a subscriber's billing period.
class FinancialReport {
  const FinancialReport({
    required this.totalSpendSom,
    required this.byCategory,
    required this.byDay,
    required this.topNumbers,
    required this.totalCallMinutes,
    required this.totalDataMb,
    required this.totalSmsCount,
    required this.subscriptionSpendSom,
    required this.periodDays,
  });

  final Decimal totalSpendSom;
  final Map<BillingType, Decimal> byCategory;
  final List<DailySpend> byDay;
  final List<NumberSpend> topNumbers;
  final Decimal totalCallMinutes;
  final Decimal totalDataMb;
  final int totalSmsCount;
  final Decimal subscriptionSpendSom;
  final int periodDays;
}
