import 'package:billing_shield/core/engine/csv_parser.dart';
import 'package:billing_shield/core/engine/report_builder.dart';
import 'package:billing_shield/domain/entities/billing_record.dart';
import 'package:decimal/decimal.dart';
import 'package:test/test.dart';

void main() {
  final parser = CsvParser();
  final builder = ReportBuilder();

  group('ReportBuilder exact arithmetic and aggregations', () {
    test('maintains exact Decimal sum without IEEE-754 floating-point drift', () {
      final buffer = StringBuffer('datetime,type,number,duration_sec,mb,cost_som\n');
      for (var i = 0; i < 100; i++) {
        buffer.writeln('2026-09-01 10:00:00,sms,+996700111222,0,0,0.10');
        buffer.writeln('2026-09-01 10:05:00,sms,+996700111222,0,0,0.20');
      }

      final parsed = parser.parseString(buffer.toString());
      final report = builder.build(parsed.records);

      expect(report.totalSpendSom, Decimal.parse('30.00'));
      expect(report.byCategory[BillingType.sms], Decimal.parse('30.00'));
      expect(report.byCategory[BillingType.call], Decimal.zero);
      expect(report.byCategory[BillingType.data], Decimal.zero);
      expect(report.byCategory[BillingType.subscription], Decimal.zero);
      expect(report.byCategory[BillingType.content], Decimal.zero);
    });

    test('fills continuous calendar days with 0.00 and merges 996 / +996 in topNumbers', () {
      const csv = 'datetime,type,number,duration_sec,mb,cost_som\n'
          '2026-09-01 10:00:00,call,996700123456,60,0,10.00\n'
          '2026-09-04 12:00:00,call,+996700123456,120,0,20.00\n'
          '2026-09-04 13:00:00,sms,4545,0,0,5.00\n';

      final parsed = parser.parseString(csv);
      final report = builder.build(parsed.records);

      expect(report.byDay.map((d) => d.date).toList(), <String>[
        '2026-09-01',
        '2026-09-02',
        '2026-09-03',
        '2026-09-04',
      ]);
      expect(report.byDay[1].totalSom, Decimal.zero);
      expect(report.byDay[2].totalSom, Decimal.zero);

      expect(report.topNumbers, hasLength(2));
      expect(report.topNumbers[0].normalizedNumber, '+996700123456');
      expect(report.topNumbers[0].totalSom, Decimal.parse('30.00'));
      expect(report.topNumbers[0].count, 2);
      expect(report.topNumbers[1].normalizedNumber, '4545');
      expect(report.topNumbers[1].isShortCode, isTrue);
    });
  });
}
