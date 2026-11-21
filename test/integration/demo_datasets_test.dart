import 'dart:convert';
import 'dart:io';

import 'package:billing_shield/core/engine/anomaly_detector.dart';
import 'package:billing_shield/core/engine/billing_analyzer.dart';
import 'package:billing_shield/domain/entities/analysis_result.dart';
import 'package:billing_shield/domain/entities/anomaly.dart';
import 'package:billing_shield/domain/entities/family_member.dart';
import 'package:test/test.dart';

void main() {
  final analyzer = BillingAnalyzer();
  final detector = AnomalyDetector();

  final expectedSpecs = <String, List<(AnomalyType, String)>>{
    'assets/demo/billing_01.csv': [
      (AnomalyType.newSubscription, '2026-09-05 13:05:00'),
      (AnomalyType.nightCharge, '2026-09-10 02:15:30'),
      (AnomalyType.duplicateCharge, '2026-09-16 18:10:42'),
      (AnomalyType.daySpike, '2026-09-22'),
      (AnomalyType.internationalRate, '2026-09-22 14:20:00'),
    ],
    'assets/demo/billing_02.csv': [
      (AnomalyType.newSubscription, '2026-09-04 10:30:00'),
      (AnomalyType.newSubscription, '2026-09-09 14:15:00'),
      (AnomalyType.nightCharge, '2026-09-14 04:55:10'),
      (AnomalyType.daySpike, '2026-09-21'),
    ],
    'assets/demo/billing_03.csv': [
      (AnomalyType.internationalRate, '2026-09-06 11:20:00'),
      (AnomalyType.duplicateCharge, '2026-09-13 12:00:59'),
      (AnomalyType.daySpike, '2026-09-24'),
      (AnomalyType.internationalRate, '2026-09-24 16:40:00'),
    ],
    'assets/demo/billing_04.csv': [
      (AnomalyType.newSubscription, '2026-09-03 11:00:00'),
      (AnomalyType.newSubscription, '2026-09-08 13:20:00'),
      (AnomalyType.nightCharge, '2026-09-11 00:05:00'),
      (AnomalyType.nightCharge, '2026-09-18 05:59:59'),
      (AnomalyType.daySpike, '2026-09-25'),
    ],
    'assets/demo/billing_05.csv': [
      (AnomalyType.newSubscription, '2026-09-02 12:00:00'),
      (AnomalyType.newSubscription, '2026-09-07 15:10:00'),
      (AnomalyType.duplicateCharge, '2026-09-14 21:01:00'),
      (AnomalyType.nightCharge, '2026-09-19 03:45:00'),
      (AnomalyType.daySpike, '2026-09-27'),
    ],
  };

  group('End-to-end verification on all 5 bundled demo CSVs', () {
    final results = <String, AnalysisResult>{};

    for (final entry in expectedSpecs.entries) {
      test('${entry.key} achieves >= 80% recall, <= 2 false positives, and valid anomalies.json', () {
        final file = File(entry.key);
        expect(file.existsSync(), isTrue);

        final res = analyzer.analyzeCsvBytes(
          file.readAsBytesSync(),
          sourceName: entry.key.split('/').last,
        );
        results[entry.key] = res;

        final detectedSet =
            res.anomalies.map((a) => (a.type, a.datetime)).toSet();
        final expectedSet = entry.value.toSet();

        final truePositives = detectedSet.intersection(expectedSet).length;
        final recall = truePositives / expectedSet.length;
        final falsePositives = detectedSet.difference(expectedSet).length;

        expect(recall, greaterThanOrEqualTo(0.80));
        expect(falsePositives, lessThanOrEqualTo(2));
        expect(truePositives, equals(expectedSet.length));
        expect(falsePositives, equals(0));
        expect(res.droppedRows, isNotEmpty);

        // Jury anomalies.json schema check.
        final encoded = analyzer.encodeAnomaliesJson(res.anomalies);
        final decoded = jsonDecode(encoded) as List<dynamic>;
        expect(decoded, hasLength(res.anomalies.length));
        for (final item in decoded) {
          final map = item as Map<String, dynamic>;
          expect(
            map.keys,
            containsAll(<String>[
              'datetime',
              'type',
              'anomaly_type',
              'amount_som',
              'reason',
            ]),
          );
          expect(map.keys, hasLength(5));
        }
      });
    }

    test('Family Shield detects cross-account reputation threats (4545 and 7070)', () {
      final members = <FamilyMemberProfile>[
        FamilyMemberProfile(
          id: '1',
          name: 'Я',
          roleLabel: 'Азамат',
          phone: '+996700112233',
          operatorName: 'O!',
          result: analyzer.analyzeCsvBytes(
            File('assets/demo/billing_01.csv').readAsBytesSync(),
          ),
        ),
        FamilyMemberProfile(
          id: '2',
          name: 'Мама',
          roleLabel: 'Гульнара',
          phone: '+996550223344',
          operatorName: 'Mega',
          result: analyzer.analyzeCsvBytes(
            File('assets/demo/billing_02.csv').readAsBytesSync(),
          ),
        ),
        FamilyMemberProfile(
          id: '4',
          name: 'Бабушка',
          roleLabel: 'Айша',
          phone: '+996702334455',
          operatorName: 'O!',
          result: analyzer.analyzeCsvBytes(
            File('assets/demo/billing_04.csv').readAsBytesSync(),
          ),
        ),
        FamilyMemberProfile(
          id: '5',
          name: 'Брат',
          roleLabel: 'Тимур',
          phone: '+996777112233',
          operatorName: 'Beeline',
          result: analyzer.analyzeCsvBytes(
            File('assets/demo/billing_05.csv').readAsBytesSync(),
          ),
        ),
      ];

      final flags = detector.detectFamilyReputation(members);
      final codes = flags.map((f) => f.shortCode).toSet();
      expect(codes, containsAll(<String>['4545', '7070']));
    });
  });
}
