import 'package:billing_shield/core/engine/anomaly_detector.dart';
import 'package:billing_shield/core/engine/csv_parser.dart';
import 'package:billing_shield/core/engine/explainer.dart';
import 'package:billing_shield/core/engine/report_builder.dart';
import 'package:billing_shield/domain/entities/analysis_result.dart';
import 'package:billing_shield/domain/entities/anomaly.dart';
import 'package:billing_shield/domain/entities/family_member.dart';
import 'package:decimal/decimal.dart';
import 'package:test/test.dart';

void main() {
  final parser = CsvParser();
  final builder = ReportBuilder();
  final detector = AnomalyDetector();

  List<Anomaly> runDetect(String csv) {
    final parsed = parser.parseString(csv);
    final report = builder.build(parsed.records);
    return detector.detect(parsed.records, report);
  }

  group('Boundary cases for all 5 mandatory anomaly detectors', () {
    test('night_charge flags 00:00:00 and 05:59:59, excludes 06:00:00, zero-cost, and calls', () {
      const csv = 'datetime,type,number,duration_sec,mb,cost_som\n'
          '2026-09-01 00:00:00,sms,4545,0,0,5.00\n'
          '2026-09-01 05:59:59,content,4545,0,0,12.00\n'
          '2026-09-01 06:00:00,sms,4545,0,0,5.00\n'
          '2026-09-01 03:00:00,sms,4545,0,0,0.00\n'
          '2026-09-01 02:30:00,call,+996700112233,60,0,10.00\n';

      final anomalies = runDetect(csv)
          .where((a) => a.type == AnomalyType.nightCharge)
          .toList();

      expect(anomalies, hasLength(2));
      expect(anomalies[0].datetime, '2026-09-01 00:00:00');
      expect(anomalies[1].datetime, '2026-09-01 05:59:59');
      expect(anomalies[0].overchargeSom, Decimal.parse('5.00'));
    });

    test('duplicate_charge flags <= 60s later charge, excludes 61s', () {
      const csv = 'datetime,type,number,duration_sec,mb,cost_som\n'
          '2026-09-01 12:00:00,sms,+996555889900,0,0,10.00\n'
          '2026-09-01 12:01:00,sms,996555889900,0,0,10.00\n'
          '2026-09-02 12:00:00,sms,+996555889900,0,0,10.00\n'
          '2026-09-02 12:01:01,sms,+996555889900,0,0,10.00\n';

      final anomalies = runDetect(csv)
          .where((a) => a.type == AnomalyType.duplicateCharge)
          .toList();

      expect(anomalies, hasLength(1));
      expect(anomalies.first.datetime, '2026-09-01 12:01:00');
      expect(anomalies.first.overchargeSom, Decimal.parse('10.00'));
    });

    test('new_subscription enforces strictly 3-6 digit short codes and first occurrence only', () {
      const csv = 'datetime,type,number,duration_sec,mb,cost_som\n'
          '2026-09-01 10:00:00,subscription,12,0,0,10.00\n'
          '2026-09-02 10:00:00,subscription,909,0,0,15.00\n'
          '2026-09-03 10:00:00,subscription,909,0,0,15.00\n'
          '2026-09-04 10:00:00,subscription,123456,0,0,20.00\n'
          '2026-09-05 10:00:00,subscription,1234567,0,0,25.00\n'
          '2026-09-06 10:00:00,subscription,+4545,0,0,30.00\n';

      final anomalies = runDetect(csv)
          .where((a) => a.type == AnomalyType.newSubscription)
          .toList();

      expect(anomalies, hasLength(2));
      expect(anomalies[0].number, '909');
      expect(anomalies[1].number, '123456');
    });

    test('day_spike skips first 7 days, handles std == 0 without crash, uses ddof=0', () {
      // Days 1..7 all constant 20.00 -> std == 0 -> day 8 must NOT throw ZeroDivisionError.
      final buf = StringBuffer('datetime,type,number,duration_sec,mb,cost_som\n');
      for (var d = 1; d <= 7; d++) {
        buf.writeln('2026-09-0$d 12:00:00,call,+996700112233,60,0,20.00');
      }
      buf.writeln('2026-09-08 12:00:00,call,+996700112233,60,0,200.00');
      final zeroStdAnomalies = runDetect(buf.toString())
          .where((a) => a.type == AnomalyType.daySpike)
          .toList();
      expect(zeroStdAnomalies, isEmpty);

      // Now days 1..7 have slight variance (10, 12, 10, 12, 10, 12, 11) and day 8 spikes.
      final buf2 = StringBuffer('datetime,type,number,duration_sec,mb,cost_som\n');
      final vals = [10, 12, 10, 12, 10, 12, 11];
      for (var d = 1; d <= 7; d++) {
        buf2.writeln('2026-09-0$d 12:00:00,call,+996700112233,60,0,${vals[d - 1]}.00');
      }
      buf2.writeln('2026-09-08 12:00:00,call,+996700112233,60,0,100.00');
      final spikeAnomalies = runDetect(buf2.toString())
          .where((a) => a.type == AnomalyType.daySpike)
          .toList();
      expect(spikeAnomalies, hasLength(1));
      expect(spikeAnomalies.first.datetime, '2026-09-08');
      expect(spikeAnomalies.first.overchargeSom, Decimal.zero);
    });

    test('international_rate excludes +996, boundary 20.00/min, and duration_sec == 0', () {
      const csv = 'datetime,type,number,duration_sec,mb,cost_som\n'
          '2026-09-01 12:00:00,call,+996700112233,60,0,50.00\n'
          '2026-09-02 12:00:00,call,+905321234567,60,0,20.00\n'
          '2026-09-03 12:00:00,call,+905321234567,0,0,25.00\n'
          '2026-09-04 12:00:00,call,+905321234567,60,0,20.01\n';

      final anomalies = runDetect(csv)
          .where((a) => a.type == AnomalyType.internationalRate)
          .toList();

      expect(anomalies, hasLength(1));
      expect(anomalies.first.datetime, '2026-09-04 12:00:00');
      expect(anomalies.first.overchargeSom, Decimal.parse('0.01'));
    });

    test('total overcharge avoids double counting same row across rules and excludes day_spike', () {
      const csv = 'datetime,type,number,duration_sec,mb,cost_som\n'
          '2026-09-01 02:00:00,content,4545,0,0,15.00\n'
          '2026-09-01 02:00:30,content,4545,0,0,15.00\n';

      final anomalies = runDetect(csv);
      // Row 2 triggers night_charge (15); Row 3 triggers BOTH night_charge (15) & duplicate_charge (15).
      // Total overcharge must be 30.00 (not 45.00).
      expect(anomalies.length, 3);
      expect(Explainer.calculateTotalOvercharge(anomalies), Decimal.parse('30.00'));
    });

    test('detectFamilyReputation flags short codes hitting >= 2 family members', () {
      const csvA = 'datetime,type,number,duration_sec,mb,cost_som\n'
          '2026-09-01 12:00:00,subscription,4545,0,0,15.00\n'
          '2026-09-02 12:00:00,subscription,999,0,0,10.00\n';
      const csvB = 'datetime,type,number,duration_sec,mb,cost_som\n'
          '2026-09-03 12:00:00,content,4545,0,0,20.00\n';

      AnalysisResult buildResult(String csv, String name) {
        final p = parser.parseString(csv);
        final r = builder.build(p.records);
        return AnalysisResult(
          sourceName: name,
          records: p.records,
          droppedRows: p.droppedRows,
          report: r,
          anomalies: const [],
          totalOverchargeSom: Decimal.zero,
          annualLeakSom: Decimal.zero,
          summaryRu: '',
          summaryKy: '',
        );
      }

      final flags = detector.detectFamilyReputation([
        FamilyMemberProfile(
          id: 'a',
          name: 'Я',
          roleLabel: 'Я',
          phone: '+9967001',
          operatorName: 'O!',
          result: buildResult(csvA, 'a.csv'),
        ),
        FamilyMemberProfile(
          id: 'b',
          name: 'Мама',
          roleLabel: 'Мама',
          phone: '+9967002',
          operatorName: 'Mega',
          result: buildResult(csvB, 'b.csv'),
        ),
      ]);

      expect(flags, hasLength(1));
      expect(flags.first.shortCode, '4545');
      expect(flags.first.affectedMemberNames, <String>['Я', 'Мама']);
      expect(flags.first.totalFamilyLossSom, Decimal.parse('35.00'));
    });
  });
}
