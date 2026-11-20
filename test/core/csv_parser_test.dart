import 'dart:convert';

import 'package:billing_shield/core/engine/csv_parser.dart';
import 'package:billing_shield/domain/entities/billing_record.dart';
import 'package:billing_shield/domain/entities/dropped_row.dart';
import 'package:decimal/decimal.dart';
import 'package:test/test.dart';

void main() {
  final parser = CsvParser();

  group('CsvParser encodings, delimiters, and line endings', () {
    test('parses UTF-8 with BOM bytes, CRLF, semicolon delimiter, and comma decimals', () {
      const csvText = 'datetime;type;number;duration_sec;mb;cost_som\r\n'
          '04.09.2026 10:30:00;subscription;4545;0;0;12,50\r\n'
          '2026-09-05 14:00:00;call;996700112233;120;0;18,75\r\n';
      final bytes = <int>[0xEF, 0xBB, 0xBF, ...utf8.encode(csvText)];

      final result = parser.parseBytes(bytes);

      expect(result.droppedRows, isEmpty);
      expect(result.records, hasLength(2));

      expect(result.records[0].formattedDatetime, '2026-09-04 10:30:00');
      expect(result.records[0].type, BillingType.subscription);
      expect(result.records[0].costSom, Decimal.parse('12.50'));

      expect(result.records[1].normalizedNumber, '+996700112233');
      expect(result.records[1].costSom, Decimal.parse('18.75'));
    });

    test('parses quoted comma decimals inside comma-delimited CSV', () {
      const csvText = 'datetime,type,number,duration_sec,mb,cost_som\n'
          '2026-09-13 12:00:00,sms,+996555889900,0,0,"15,50"\n';

      final result = parser.parseString('\uFEFF$csvText');

      expect(result.droppedRows, isEmpty);
      expect(result.records, hasLength(1));
      expect(result.records.first.costSom, Decimal.parse('15.50'));
    });
  });

  group('CsvParser 5-step strict validation cascade', () {
    test('drops empty_line, column_count, unknown_type, bad_datetime, and bad_number', () {
      const csv = 'datetime,type,number,duration_sec,mb,cost_som\n'
          '\n'
          '2026-09-01 10:00:00,call,+996700112233\n'
          '2026-09-01 10:00:00,roaming,+996700112233,60,0,10.00\n'
          '2026-09-31 10:00:00,call,+996700112233,60,0,10.00\n'
          '2026-02-29 10:00:00,call,+996700112233,60,0,10.00\n'
          '2026-09-01 24:00:00,call,+996700112233,60,0,10.00\n'
          '2026-09-01 10:00:00,call,+996700112233,60,0,NaN\n'
          '2026-09-01 10:00:00,call,+996700112233,60,0,Infinity\n'
          '2026-09-01 10:00:00,call,+996700112233,60,0,-5.00\n'
          '2026-09-01 10:00:00,call,+996700112233,60,0,free\n'
          '2024-02-29 10:00:00,call,+996700112233,60,0,5.00\n';

      final result = parser.parseString(csv);

      expect(result.records, hasLength(1));
      expect(result.records.first.formattedDatetime, '2024-02-29 10:00:00');

      expect(
        result.droppedRows.map((d) => d.reason).toList(),
        <DropReason>[
          DropReason.emptyLine,
          DropReason.columnCount,
          DropReason.unknownType,
          DropReason.badDatetime, // 2026-09-31
          DropReason.badDatetime, // 2026-02-29 (non-leap)
          DropReason.badDatetime, // hour 24
          DropReason.badNumber, // NaN
          DropReason.badNumber, // Infinity
          DropReason.badNumber, // negative
          DropReason.badNumber, // text
        ],
      );
    });
  });
}
