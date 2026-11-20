import 'dart:io';

import 'package:billing_shield/core/engine/billing_analyzer.dart';
import 'package:billing_shield/domain/entities/anomaly.dart';
import 'package:billing_shield/domain/entities/billing_record.dart';
import 'package:decimal/decimal.dart';
import 'package:test/test.dart';

void main() {
  final analyzer = BillingAnalyzer();

  void assertMatchesExpected({
    required String csvPath,
    required int validRows,
    required int droppedRows,
    required String totalSom,
    required Map<BillingType, String> byCategory,
    required Map<String, String> byDay,
    required List<(String, String)> top5,
    required List<({AnomalyType anomalyType, String datetime, String amountSom})>
        expectedAnomalies,
  }) {
    final file = File(csvPath);
    expect(file.existsSync(), isTrue);
    final res = analyzer.analyzeCsvBytes(file.readAsBytesSync());

    expect(res.records.length, validRows, reason: '$csvPath valid_rows');
    expect(res.droppedRows.length, droppedRows, reason: '$csvPath dropped_rows');
    expect(
      res.report.totalSpendSom.round(scale: 2),
      Decimal.parse(totalSom),
      reason: '$csvPath total_som',
    );

    for (final entry in byCategory.entries) {
      expect(
        res.report.byCategory[entry.key]!.round(scale: 2),
        Decimal.parse(entry.value),
        reason: '$csvPath category ${entry.key.wireName}',
      );
    }

    final actualByDay = <String, Decimal>{
      for (final d in res.report.byDay) d.date: d.totalSom.round(scale: 2),
    };
    for (final entry in byDay.entries) {
      expect(
        actualByDay[entry.key],
        Decimal.parse(entry.value),
        reason: '$csvPath day ${entry.key}',
      );
    }

    expect(res.report.topNumbers.length, top5.length);
    for (var i = 0; i < top5.length; i++) {
      expect(res.report.topNumbers[i].normalizedNumber, top5[i].$1);
      expect(
        res.report.topNumbers[i].totalSom.round(scale: 2),
        Decimal.parse(top5[i].$2),
      );
    }

    expect(
      res.anomalies.length,
      expectedAnomalies.length,
      reason:
          '$csvPath anomalies: ${res.anomalies.map((a) => "${a.type.wireName}@${a.datetime}").toList()}',
    );

    for (final exp in expectedAnomalies) {
      final matches = res.anomalies.where((a) {
        if (a.type != exp.anomalyType) return false;
        if (exp.anomalyType == AnomalyType.daySpike) {
          return exp.datetime.startsWith(a.datetime);
        }
        return a.datetime == exp.datetime;
      }).toList();
      expect(
        matches,
        hasLength(1),
        reason: '$csvPath missing ${exp.anomalyType.wireName} at ${exp.datetime}',
      );
      final actual = matches.first;
      if (exp.anomalyType == AnomalyType.daySpike) {
        final spikeDelta = (actual.costSom - (actual.baselineMeanSom ?? Decimal.zero))
            .round(scale: 2);
        expect(spikeDelta, Decimal.parse(exp.amountSom));
      } else {
        expect(actual.overchargeSom.round(scale: 2), Decimal.parse(exp.amountSom));
      }
    }
  }

  group('Official hackathon verification datasets', () {
    test('Case 338 rows (valid=338, dropped=7, total=1230.16)', () {
      assertMatchesExpected(
        csvPath: 'test/fixtures/official/case_338.csv',
        validRows: 338,
        droppedRows: 7,
        totalSom: '1230.16',
        byCategory: const {
          BillingType.call: '873.60',
          BillingType.sms: '73.00',
          BillingType.data: '222.56',
          BillingType.subscription: '16.00',
          BillingType.content: '45.00',
        },
        byDay: const {
          '2026-09-01': '28.77',
          '2026-09-12': '28.52',
          '2026-09-25': '317.25',
          '2026-09-30': '47.36',
        },
        top5: const [
          ('+996777165026', '207.60'),
          ('+996777336580', '151.40'),
          ('+996700188574', '120.00'),
          ('+996700029833', '93.60'),
          ('+971007731297', '66.00'),
        ],
        expectedAnomalies: const [
          (
            anomalyType: AnomalyType.nightCharge,
            datetime: '2026-09-12 05:37:24',
            amountSom: '15.00',
          ),
          (
            anomalyType: AnomalyType.newSubscription,
            datetime: '2026-09-23 12:00:35',
            amountSom: '8.00',
          ),
          (
            anomalyType: AnomalyType.daySpike,
            datetime: '2026-09-25 00:00:00',
            amountSom: '290.97',
          ),
          (
            anomalyType: AnomalyType.internationalRate,
            datetime: '2026-09-27 10:40:38',
            amountSom: '33.00',
          ),
        ],
      );
    });

    test('Case 480 rows (valid=480, dropped=9, total=1391.32)', () {
      assertMatchesExpected(
        csvPath: 'test/fixtures/official/case_480.csv',
        validRows: 480,
        droppedRows: 9,
        totalSom: '1391.32',
        byCategory: const {
          BillingType.call: '927.92',
          BillingType.sms: '118.00',
          BillingType.data: '330.40',
          BillingType.subscription: '0.00',
          BillingType.content: '15.00',
        },
        byDay: const {
          '2026-09-01': '20.69',
          '2026-09-19': '281.00',
          '2026-09-28': '70.10',
          '2026-09-30': '33.37',
        },
        top5: const [
          ('+996777431571', '162.00'),
          ('+996770364156', '130.00'),
          ('+996700669351', '106.00'),
          ('+996505777638', '99.00'),
          ('+996555130058', '98.00'),
        ],
        expectedAnomalies: const [
          (
            anomalyType: AnomalyType.nightCharge,
            datetime: '2026-09-13 04:14:29',
            amountSom: '15.00',
          ),
          (
            anomalyType: AnomalyType.daySpike,
            datetime: '2026-09-19 00:00:00',
            amountSom: '255.74',
          ),
          (
            anomalyType: AnomalyType.internationalRate,
            datetime: '2026-09-28 17:46:15',
            amountSom: '9.59',
          ),
        ],
      );
    });

    test('Case 596 rows (valid=596, dropped=8, total=2106.02)', () {
      assertMatchesExpected(
        csvPath: 'test/fixtures/official/case_596.csv',
        validRows: 596,
        droppedRows: 8,
        totalSom: '2106.02',
        byCategory: const {
          BillingType.call: '1585.00',
          BillingType.sms: '121.00',
          BillingType.data: '374.02',
          BillingType.subscription: '16.00',
          BillingType.content: '10.00',
        },
        byDay: const {
          '2026-09-01': '50.06',
          '2026-09-12': '92.97',
          '2026-09-29': '464.95',
          '2026-09-30': '57.43',
        },
        top5: const [
          ('+996700395431', '211.00'),
          ('+996700982775', '205.00'),
          ('+996770879827', '189.00'),
          ('+996770225471', '166.50'),
          ('+996505100223', '155.00'),
        ],
        expectedAnomalies: const [
          (
            anomalyType: AnomalyType.internationalRate,
            datetime: '2026-09-07 17:54:43',
            amountSom: '41.00',
          ),
          (
            anomalyType: AnomalyType.duplicateCharge,
            datetime: '2026-09-12 16:55:54',
            amountSom: '6.00',
          ),
          (
            anomalyType: AnomalyType.nightCharge,
            datetime: '2026-09-14 01:37:37',
            amountSom: '10.00',
          ),
          (
            anomalyType: AnomalyType.newSubscription,
            datetime: '2026-09-23 12:18:37',
            amountSom: '8.00',
          ),
          (
            anomalyType: AnomalyType.daySpike,
            datetime: '2026-09-29 00:00:00',
            amountSom: '414.53',
          ),
        ],
      );
    });

    test('Case 668 rows (valid=668, dropped=13, total=1638.85)', () {
      assertMatchesExpected(
        csvPath: 'test/fixtures/official/case_668.csv',
        validRows: 668,
        droppedRows: 13,
        totalSom: '1638.85',
        byCategory: const {
          BillingType.call: '1030.00',
          BillingType.sms: '119.00',
          BillingType.data: '447.85',
          BillingType.subscription: '12.00',
          BillingType.content: '30.00',
        },
        byDay: const {
          '2026-09-01': '34.27',
          '2026-09-08': '41.89',
          '2026-09-22': '259.84',
          '2026-09-30': '49.10',
        },
        top5: const [
          ('+996220996424', '194.00'),
          ('+996555695647', '174.00'),
          ('+996220860885', '162.00'),
          ('+996770529619', '135.00'),
          ('+996770724207', '116.00'),
        ],
        expectedAnomalies: const [
          (
            anomalyType: AnomalyType.nightCharge,
            datetime: '2026-09-05 00:02:16',
            amountSom: '10.00',
          ),
          (
            anomalyType: AnomalyType.duplicateCharge,
            datetime: '2026-09-08 19:22:26',
            amountSom: '2.00',
          ),
          (
            anomalyType: AnomalyType.daySpike,
            datetime: '2026-09-22 00:00:00',
            amountSom: '218.35',
          ),
          (
            anomalyType: AnomalyType.newSubscription,
            datetime: '2026-09-25 12:45:43',
            amountSom: '12.00',
          ),
          (
            anomalyType: AnomalyType.internationalRate,
            datetime: '2026-09-29 12:50:32',
            amountSom: '22.67',
          ),
        ],
      );
    });

    test('Case 775 rows (valid=775, dropped=6, total=1919.07)', () {
      assertMatchesExpected(
        csvPath: 'test/fixtures/official/case_775.csv',
        validRows: 775,
        droppedRows: 6,
        totalSom: '1919.07',
        byCategory: const {
          BillingType.call: '1196.00',
          BillingType.sms: '160.00',
          BillingType.data: '533.07',
          BillingType.subscription: '20.00',
          BillingType.content: '10.00',
        },
        byDay: const {
          '2026-09-01': '53.42',
          '2026-09-18': '65.24',
          '2026-09-21': '348.88',
          '2026-09-30': '12.60',
        },
        top5: const [
          ('+996220863991', '577.00'),
          ('+996220358207', '226.00'),
          ('+996777676401', '196.00'),
          ('+996555306516', '124.00'),
          ('+996505281792', '65.00'),
        ],
        expectedAnomalies: const [
          (
            anomalyType: AnomalyType.newSubscription,
            datetime: '2026-09-18 12:35:33',
            amountSom: '10.00',
          ),
          (
            anomalyType: AnomalyType.daySpike,
            datetime: '2026-09-21 00:00:00',
            amountSom: '292.61',
          ),
          (
            anomalyType: AnomalyType.duplicateCharge,
            datetime: '2026-09-29 11:35:22',
            amountSom: '2.00',
          ),
        ],
      );
    });
  });
}
