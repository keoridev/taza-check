import 'dart:math' as math;

import 'package:decimal/decimal.dart';

import '../../domain/entities/anomaly.dart';
import '../../domain/entities/billing_record.dart';
import '../../domain/entities/family_member.dart';
import '../../domain/entities/financial_report.dart';
import '../utils/decimal_utils.dart';
import '../utils/phone_normalizer.dart';
import 'explainer.dart';

/// Runs all 5 mandatory Task 4 anomaly detectors plus cross-family reputation checks.
class AnomalyDetector {
  static final Decimal _twenty = Decimal.fromInt(20);
  static final Decimal _sixty = Decimal.fromInt(60);

  /// Detects `day_spike`, `night_charge`, `new_subscription`,
  /// `duplicate_charge`, and `international_rate` anomalies.
  List<Anomaly> detect(
    List<BillingRecord> records,
    FinancialReport report,
  ) {
    final sorted = List<BillingRecord>.from(records)
      ..sort((a, b) {
        final cmp = a.timestamp.compareTo(b.timestamp);
        if (cmp != 0) return cmp;
        return a.rowNumber.compareTo(b.rowNumber);
      });

    final anomalies = <Anomaly>[];
    var seq = 0;

    // 1. day_spike: z-score > 3 relative to rolling 7-day window (ddof = 0).
    final days = report.byDay;
    for (var i = 7; i < days.length; i++) {
      final window = days.sublist(i - 7, i);
      final values = window.map((d) => d.totalSom.toDouble()).toList();
      final mean = values.reduce((a, b) => a + b) / 7.0;
      var varianceSum = 0.0;
      for (final v in values) {
        final diff = v - mean;
        varianceSum += diff * diff;
      }
      final pstdev = math.sqrt(varianceSum / 7.0);
      if (pstdev <= 1e-12) {
        // Handle std == 0 gracefully without division by zero.
        continue;
      }
      final current = days[i].totalSom.toDouble();
      final zScore = (current - mean) / pstdev;
      if (zScore > 3.0) {
        final meanSom = Decimal.parse(mean.toStringAsFixed(2));
        final text = Explainer.explainDaySpike(
          date: days[i].date,
          totalSom: days[i].totalSom,
          meanSom: meanSom,
          zScore: zScore,
        );
        anomalies.add(
          Anomaly(
            id: 'day_spike_${days[i].date}_${seq++}',
            datetime: days[i].date,
            type: AnomalyType.daySpike,
            reason: text.reason,
            costSom: days[i].totalSom,
            overchargeSom: Decimal.zero,
            explanationRu: text.ru,
            explanationKy: text.ky,
            explanationEn: text.en,
            zScore: zScore,
            baselineMeanSom: meanSom,
          ),
        );
      }
    }

    final seenShortCodes = <String>{};
    final lastSeenBySignature = <String, DateTime>{};

    for (final record in sorted) {
      final ussdHint = Explainer.buildUssdHint(record);

      // 2. night_charge: paid sms or content in [00:00:00, 06:00:00).
      if (record.costSom > Decimal.zero &&
          (record.type == BillingType.sms ||
              record.type == BillingType.content) &&
          record.timestamp.hour >= 0 &&
          record.timestamp.hour < 6) {
        final text = Explainer.explainNightCharge(record);
        anomalies.add(
          Anomaly(
            id: 'night_charge_${record.rowNumber}_${seq++}',
            datetime: record.formattedDatetime,
            type: AnomalyType.nightCharge,
            reason: text.reason,
            number: record.normalizedNumber.isEmpty
                ? record.rawNumber
                : record.normalizedNumber,
            costSom: record.costSom,
            overchargeSom: record.costSom,
            rowNumber: record.rowNumber,
            ussdHint: ussdHint,
            explanationRu: text.ru,
            explanationKy: text.ky,
            explanationEn: text.en,
          ),
        );
      }

      // 3. new_subscription: first chronological subscription to 3-6 digit short code.
      if (record.type == BillingType.subscription &&
          record.costSom > Decimal.zero &&
          isShortCode(record.rawNumber)) {
        final shortCode = cleanPhone(record.rawNumber);
        if (seenShortCodes.add(shortCode)) {
          final text = Explainer.explainNewSubscription(record);
          anomalies.add(
            Anomaly(
              id: 'new_subscription_${record.rowNumber}_${seq++}',
              datetime: record.formattedDatetime,
              type: AnomalyType.newSubscription,
              reason: text.reason,
              number: shortCode,
              costSom: record.costSom,
              overchargeSom: record.costSom,
              rowNumber: record.rowNumber,
              ussdHint: ussdHint,
              explanationRu: text.ru,
              explanationKy: text.ky,
              explanationEn: text.en,
            ),
          );
        }
      }

      // 4. duplicate_charge: identical paid charge within <= 60 seconds (flag later).
      if (record.costSom > Decimal.zero) {
        final sig =
            '${record.type.wireName}|${record.normalizedNumber}|${record.durationSec}|${record.mb}|${record.costSom}';
        final prevTimestamp = lastSeenBySignature[sig];
        if (prevTimestamp != null) {
          final deltaSeconds = record.timestamp.difference(prevTimestamp).inSeconds;
          if (deltaSeconds >= 0 && deltaSeconds <= 60) {
            final text = Explainer.explainDuplicateCharge(record, deltaSeconds);
            anomalies.add(
              Anomaly(
                id: 'duplicate_charge_${record.rowNumber}_${seq++}',
                datetime: record.formattedDatetime,
                type: AnomalyType.duplicateCharge,
                reason: text.reason,
                number: record.normalizedNumber.isEmpty
                    ? record.rawNumber
                    : record.normalizedNumber,
                costSom: record.costSom,
                overchargeSom: record.costSom,
                rowNumber: record.rowNumber,
                ussdHint: ussdHint,
                explanationRu: text.ru,
                explanationKy: text.ky,
                explanationEn: text.en,
              ),
            );
          }
        }
        lastSeenBySignature[sig] = record.timestamp;
      }

      // 5. international_rate: outgoing call to non-+996 international number > 20 KGS/min.
      if (record.type == BillingType.call &&
          isInternational(record.normalizedNumber) &&
          record.durationSec > Decimal.zero) {
        if (record.costSom * _sixty > _twenty * record.durationSec) {
          final allowed = divToDecimal(
            _twenty * record.durationSec,
            _sixty,
            scale: 10,
          );
          final diff = record.costSom - allowed;
          final overcharge =
              diff > Decimal.zero ? diff.round(scale: 2) : Decimal.zero;
          final text = Explainer.explainInternationalRate(record, overcharge);
          anomalies.add(
            Anomaly(
              id: 'international_rate_${record.rowNumber}_${seq++}',
              datetime: record.formattedDatetime,
              type: AnomalyType.internationalRate,
              reason: text.reason,
              number: record.normalizedNumber,
              costSom: record.costSom,
              overchargeSom: overcharge,
              rowNumber: record.rowNumber,
              ussdHint: 'Проверьте роуминг/международные пакеты у оператора',
              explanationRu: text.ru,
              explanationKy: text.ky,
              explanationEn: text.en,
            ),
          );
        }
      }
    }

    anomalies.sort((a, b) {
      final dtCmp = a.datetime.compareTo(b.datetime);
      if (dtCmp != 0) return dtCmp;
      final rowCmp = (a.rowNumber ?? -1).compareTo(b.rowNumber ?? -1);
      if (rowCmp != 0) return rowCmp;
      return a.type.index.compareTo(b.type.index);
    });

    return anomalies;
  }

  /// Detects short codes draining multiple family members across accounts.
  List<FamilyReputationFlag> detectFamilyReputation(
    List<FamilyMemberProfile> members,
  ) {
    final memberNamesByCode = <String, Map<String, String>>{};
    final lossByCode = <String, Decimal>{};
    final countByCode = <String, int>{};

    for (final member in members) {
      final result = member.result;
      if (result == null) continue;
      for (final record in result.records) {
        if (record.costSom <= Decimal.zero || !isShortCode(record.rawNumber)) {
          continue;
        }
        final code = cleanPhone(record.rawNumber);
        memberNamesByCode.putIfAbsent(code, () => <String, String>{})[member.id] =
            member.name;
        lossByCode[code] = (lossByCode[code] ?? Decimal.zero) + record.costSom;
        countByCode[code] = (countByCode[code] ?? 0) + 1;
      }
    }

    final flags = <FamilyReputationFlag>[];
    for (final entry in memberNamesByCode.entries) {
      if (entry.value.length < 2) continue;
      final code = entry.key;
      final names = entry.value.values.toList();
      final totalLoss = (lossByCode[code] ?? Decimal.zero).round(scale: 2);
      final count = countByCode[code] ?? 0;
      final lossStr = formatSom(totalLoss);
      final membersJoined = names.join(', ');

      flags.add(
        FamilyReputationFlag(
          shortCode: code,
          affectedMemberNames: names,
          totalFamilyLossSom: totalLoss,
          chargeCount: count,
          ussdHint: 'SMS «СТОП» на $code',
          explanationRu:
              'Короткий номер $code списал $lossStr сом ($count списаний) сразу у нескольких членов семьи: $membersJoined.',
          explanationKy:
              '$code кыска номери үй-бүлөнүн бир нече мүчөсүнөн ($membersJoined) жалпы $lossStr сом ($count жолу) алып салды.',
          explanationEn:
              'Short code $code charged $lossStr KGS ($count charges) across multiple family members: $membersJoined.',
        ),
      );
    }

    flags.sort((a, b) {
      final cmp = b.totalFamilyLossSom.compareTo(a.totalFamilyLossSom);
      if (cmp != 0) return cmp;
      return a.shortCode.compareTo(b.shortCode);
    });
    return flags;
  }
}
