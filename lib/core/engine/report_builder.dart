import 'package:decimal/decimal.dart';

import '../../domain/entities/billing_record.dart';
import '../../domain/entities/financial_report.dart';
import '../utils/date_utils.dart';
import '../utils/decimal_utils.dart';
import '../utils/phone_normalizer.dart';

/// Aggregates validated [BillingRecord] rows into an exact [FinancialReport].
class ReportBuilder {
  /// Builds the financial report using [Decimal] arithmetic exclusively.
  FinancialReport build(List<BillingRecord> records) {
    final byCategory = <BillingType, Decimal>{
      for (final type in BillingType.values) type: Decimal.zero,
    };

    var totalSpendSom = Decimal.zero;
    var totalCallSec = Decimal.zero;
    var totalDataMb = Decimal.zero;
    var totalSmsCount = 0;

    final dailyTotals = <String, Decimal>{};
    final dailyCounts = <String, int>{};
    final numberTotals = <String, Decimal>{};
    final numberCounts = <String, int>{};

    DateTime? minDay;
    DateTime? maxDay;

    for (final record in records) {
      totalSpendSom += record.costSom;
      byCategory[record.type] = byCategory[record.type]! + record.costSom;

      if (record.type == BillingType.call) {
        totalCallSec += record.durationSec;
      } else if (record.type == BillingType.data) {
        totalDataMb += record.mb;
      } else if (record.type == BillingType.sms) {
        totalSmsCount++;
      }

      final dayKey = formatDate(record.timestamp);
      final dayUtc = DateTime.utc(
        record.timestamp.year,
        record.timestamp.month,
        record.timestamp.day,
      );
      if (minDay == null || dayUtc.isBefore(minDay)) {
        minDay = dayUtc;
      }
      if (maxDay == null || dayUtc.isAfter(maxDay)) {
        maxDay = dayUtc;
      }

      dailyTotals[dayKey] = (dailyTotals[dayKey] ?? Decimal.zero) + record.costSom;
      dailyCounts[dayKey] = (dailyCounts[dayKey] ?? 0) + 1;

      if (record.normalizedNumber.isNotEmpty) {
        numberTotals[record.normalizedNumber] =
            (numberTotals[record.normalizedNumber] ?? Decimal.zero) +
                record.costSom;
        numberCounts[record.normalizedNumber] =
            (numberCounts[record.normalizedNumber] ?? 0) + 1;
      }
    }

    final byDay = <DailySpend>[];
    if (minDay != null && maxDay != null) {
      var cursor = minDay;
      while (!cursor.isAfter(maxDay)) {
        final key = formatDate(cursor);
        byDay.add(
          DailySpend(
            date: key,
            utcDate: cursor,
            totalSom: dailyTotals[key] ?? Decimal.zero,
            recordCount: dailyCounts[key] ?? 0,
          ),
        );
        cursor = DateTime.utc(cursor.year, cursor.month, cursor.day + 1);
      }
    }

    final rankedNumbers = numberTotals.entries
        .where((e) => e.value > Decimal.zero)
        .map(
          (e) => NumberSpend(
            normalizedNumber: e.key,
            totalSom: e.value,
            count: numberCounts[e.key] ?? 0,
            isShortCode: isShortCode(e.key),
          ),
        )
        .toList()
      ..sort((a, b) {
        final cmp = b.totalSom.compareTo(a.totalSom);
        if (cmp != 0) return cmp;
        return a.normalizedNumber.compareTo(b.normalizedNumber);
      });

    final topNumbers =
        rankedNumbers.length > 5 ? rankedNumbers.sublist(0, 5) : rankedNumbers;

    final totalCallMinutes =
        divToDecimal(totalCallSec, Decimal.fromInt(60), scale: 4);

    return FinancialReport(
      totalSpendSom: totalSpendSom,
      byCategory: byCategory,
      byDay: byDay,
      topNumbers: topNumbers,
      totalCallMinutes: totalCallMinutes,
      totalDataMb: totalDataMb,
      totalSmsCount: totalSmsCount,
      subscriptionSpendSom:
          byCategory[BillingType.subscription]! + byCategory[BillingType.content]!,
      periodDays: byDay.length,
    );
  }
}
