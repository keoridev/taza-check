import 'package:decimal/decimal.dart';

import '../../domain/entities/anomaly.dart';
import '../../domain/entities/billing_record.dart';
import '../../domain/entities/dropped_row.dart';
import '../../domain/entities/financial_report.dart';
import '../constants/app_strings.dart';
import '../utils/decimal_utils.dart';
import '../utils/phone_normalizer.dart';

/// Deterministic bilingual explanations, USSD/SMS unsubscribe hints, and
/// non-double-counted overcharge aggregation.
abstract final class Explainer {
  /// Calculates total recoverable overcharge without double-counting:
  /// excludes `day_spike` (an aggregate day alert) and keeps only the maximum
  /// overcharge when a single CSV row triggers multiple detectors.
  static Decimal calculateTotalOvercharge(List<Anomaly> anomalies) {
    final byRow = <int, Decimal>{};
    var rowlessTotal = Decimal.zero;

    for (final anomaly in anomalies) {
      if (anomaly.type == AnomalyType.daySpike) {
        continue;
      }
      final row = anomaly.rowNumber;
      if (row == null) {
        rowlessTotal += anomaly.overchargeSom;
      } else {
        final existing = byRow[row];
        if (existing == null || anomaly.overchargeSom > existing) {
          byRow[row] = anomaly.overchargeSom;
        }
      }
    }

    var total = rowlessTotal;
    for (final amount in byRow.values) {
      total += amount;
    }
    return total.round(scale: 2);
  }

  /// Generates an actionable 1-tap USSD or SMS unsubscribe hint for [record].
  static String? buildUssdHint(BillingRecord record) {
    if (isShortCode(record.rawNumber)) {
      final code = cleanPhone(record.rawNumber);
      return 'SMS «СТОП» на $code (O!: *155#, Beeline: *115#, Mega: *222#)';
    }
    if (record.type == BillingType.subscription ||
        record.type == BillingType.content) {
      return 'USSD для проверки подписок: *155# (O!), *115# (Beeline), *222# (Mega)';
    }
    return null;
  }

  /// Builds concise RU reason for `anomalies.json` plus full RU, KY & EN explanations.
  static ({String reason, String ru, String ky, String en}) explainDaySpike({
    required String date,
    required Decimal totalSom,
    required Decimal meanSom,
    required double zScore,
  }) {
    final zStr = zScore.toStringAsFixed(2);
    final totalStr = formatSom(totalSom);
    final meanStr = formatSom(meanSom);
    return (
      reason:
          'Резкий всплеск расходов $date: $totalStr сом (среднее $meanStr сом, z=$zStr > 3)',
      ru: 'За $date расходы резко выросли до $totalStr сом при среднем уровне $meanStr сом за предыдущие 7 дней (z-score = $zStr). Проверьте детализацию операций за этот день.',
      ky: '$date күнү чыгымдар кескин өсүп, $totalStr сомго жетти (мурунку 7 күндүн орточосу $meanStr сом, z-score = $zStr). Ушул күндөгү төлөмдөрдү текшериңиз.',
      en: 'On $date spending spiked to $totalStr KGS vs the 7-day average of $meanStr KGS (z-score = $zStr). Review your itemized charges for this day.',
    );
  }

  static ({String reason, String ru, String ky, String en}) explainNightCharge(
    BillingRecord record,
  ) {
    final costStr = formatSom(record.costSom);
    final numberDisplay =
        record.normalizedNumber.isEmpty ? 'короткий номер' : record.normalizedNumber;
    final numberDisplayEn =
        record.normalizedNumber.isEmpty ? 'short code' : record.normalizedNumber;
    return (
      reason:
          'Ночное списание (${record.type.wireName}) в ${record.formattedDatetime} на $numberDisplay: $costStr сом',
      ru: 'В ночное время (${record.formattedDatetime}, с 00:00 до 06:00) списано $costStr сом за ${record.type.wireName} на $numberDisplay. Часто это признак скрытых платных рассылок.',
      ky: 'Түнкү убакта (${record.formattedDatetime}, 00:00–06:00 аралыгында) $numberDisplay номерине ${record.type.wireName} үчүн $costStr сом алынды. Бул жашыруун акы төлөнүүчү кызматтын белгиси болушу мүмкүн.',
      en: 'Nighttime charge (${record.formattedDatetime}, 00:00–06:00) of $costStr KGS for ${record.type.wireName} to $numberDisplayEn. Often indicates a hidden paid service.',
    );
  }

  static ({String reason, String ru, String ky, String en})
      explainNewSubscription(
    BillingRecord record,
  ) {
    final costStr = formatSom(record.costSom);
    final code = cleanPhone(record.rawNumber);
    return (
      reason: 'Первое списание за подписку на короткий номер $code: $costStr сом',
      ru: 'Обнаружена новая платная подписка на короткий номер $code ($costStr сом). За год регулярные списания могут привести к заметной утечке бюджета — отправьте СТОП на номер $code.',
      ky: '$code кыска номерине жаңы акы төлөнүүчү жазылуу аныкталды ($costStr сом). Жыл ичинде мындай төлөмдөр көп чыгымга алып келет — $code номерине СТОП сөзүн жөнөтүңүз.',
      en: 'New paid subscription detected on short code $code ($costStr KGS). Recurring charges can drain your balance over a year — send STOP to $code.',
    );
  }

  static ({String reason, String ru, String ky, String en})
      explainDuplicateCharge(
    BillingRecord record,
    int deltaSeconds,
  ) {
    final costStr = formatSom(record.costSom);
    final numberDisplay =
        record.normalizedNumber.isEmpty ? 'без номера' : record.normalizedNumber;
    final numberDisplayEn =
        record.normalizedNumber.isEmpty ? 'no number' : record.normalizedNumber;
    return (
      reason:
          'Повторное списание через $deltaSeconds сек (${record.type.wireName}, $numberDisplay): $costStr сом',
      ru: 'Идентичное списание $costStr сом (${record.type.wireName}, $numberDisplay) прошло повторно через $deltaSeconds сек (в пределах 60 сек). Вероятен технический дубль биллинга.',
      ky: '$costStr сомдук окшош төлөм (${record.type.wireName}, $numberDisplay) $deltaSeconds секунддан кийин кайра алынды (60 сек ичинде). Биллингдин техникалык катасы болушу мүмкүн.',
      en: 'Identical charge of $costStr KGS (${record.type.wireName}, $numberDisplayEn) was billed again $deltaSeconds sec later (within 60 sec). Likely a billing duplicate.',
    );
  }

  static ({String reason, String ru, String ky, String en})
      explainInternationalRate(
    BillingRecord record,
    Decimal overchargeSom,
  ) {
    final costStr = formatSom(record.costSom);
    final overStr = formatSom(overchargeSom);
    final durMin = divToDecimal(
      record.durationSec,
      Decimal.fromInt(60),
      scale: 2,
    );
    return (
      reason:
          'Международный звонок на ${record.normalizedNumber} дороже 20 сом/мин ($costStr сом за ${record.durationSec} сек, переплата $overStr сом)',
      ru: 'Исходящий международный звонок на ${record.normalizedNumber} (${durMin.toStringAsFixed(2)} мин) обошёлся в $costStr сом — выше порога 20 сом/мин. Расчётная переплата: $overStr сом.',
      ky: '${record.normalizedNumber} эл аралык номерине чалуу (${durMin.toStringAsFixed(2)} мүн) $costStr сом болду — бул 20 сом/мүн чегинен жогору. Ашыкча төлөм: $overStr сом.',
      en: 'Outgoing international call to ${record.normalizedNumber} (${durMin.toStringAsFixed(2)} min) cost $costStr KGS — above 20 KGS/min. Estimated overcharge: $overStr KGS.',
    );
  }

  /// Generates deterministic Russian, Kyrgyz & English executive summaries from verified facts.
  static ({String ru, String ky, String en}) buildDeterministicSummaries({
    required String sourceName,
    required FinancialReport report,
    required List<Anomaly> anomalies,
    required List<DroppedRow> droppedRows,
    required Decimal totalOverchargeSom,
    required Decimal annualLeakSom,
  }) {
    final totalStr = formatSom(report.totalSpendSom);
    final overStr = formatSom(totalOverchargeSom);
    final leakStr = formatSom(annualLeakSom);
    final count = anomalies.length;
    final dropped = droppedRows.length;

    if (count == 0) {
      return (
        ru: 'Файл $sourceName проанализирован (${report.periodDays} дн.). Общие расходы: $totalStr сом, подозрительных списаний не выявлено. Отброшено битых строк: $dropped.',
        ky: '$sourceName файлы текшерилди (${report.periodDays} күн). Жалпы чыгым: $totalStr сом, шектүү аномалиялар табылган жок. Бузулган саптар өткөрүлдү: $dropped.',
        en: 'Analyzed $sourceName (${report.periodDays} days). Total spend: $totalStr KGS with no suspicious charges detected. Corrupted rows skipped: $dropped.',
      );
    }

    final topAnomaly = anomalies.first;
    final ru = 'За ${report.periodDays} дн. по $sourceName потрачено $totalStr сом. '
        'Найдено аномалий: $count, возможная переплата составляет $overStr сом '
        '(годовой прогноз утечки по подпискам и контенту: $leakStr сом). '
        'Ключевой риск: ${topAnomaly.reason}. Отброшено битых строк: $dropped.';

    final ky = '$sourceName боюнча ${report.periodDays} күндө $totalStr сом сарпталды. '
        'Табылган аномалиялар: $count, мүмкүн болгон ашыкча төлөм: $overStr сом '
        '(жазылуулар боюнча жылдык жоготуу божомолу: $leakStr сом). '
        'Башкы тобокелдик: ${AppStrings.anomalyTitle(topAnomaly.type, AppLanguage.ky)}. '
        'Бузулган саптар: $dropped.';

    final en = 'Over ${report.periodDays} days in $sourceName you spent $totalStr KGS. '
        'Found $count anomalies with $overStr KGS potential overcharge '
        '(projected annual subscription leak: $leakStr KGS). '
        'Top risk: ${AppStrings.anomalyTitle(topAnomaly.type, AppLanguage.en)}. '
        'Corrupted rows skipped: $dropped.';

    return (ru: ru, ky: ky, en: en);
  }
}
