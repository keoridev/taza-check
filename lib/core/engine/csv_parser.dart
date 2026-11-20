import 'dart:convert';

import 'package:decimal/decimal.dart';

import '../../domain/entities/billing_record.dart';
import '../../domain/entities/dropped_row.dart';
import '../utils/date_utils.dart';
import '../utils/decimal_utils.dart';
import '../utils/phone_normalizer.dart';

/// Result of parsing a billing CSV file, including accepted and dropped rows.
class CsvParseResult {
  const CsvParseResult({
    required this.records,
    required this.droppedRows,
  });

  final List<BillingRecord> records;
  final List<DroppedRow> droppedRows;
}

/// Fault-tolerant billing CSV parser enforcing the 5-step validation cascade.
class CsvParser {
  static const List<String> _expectedHeader = <String>[
    'datetime',
    'type',
    'number',
    'duration_sec',
    'mb',
    'cost_som',
  ];

  /// Parses raw UTF-8 (with or without BOM) CSV [bytes].
  CsvParseResult parseBytes(List<int> bytes) {
    var offset = 0;
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      offset = 3;
    }
    final content = utf8.decode(
      offset == 0 ? bytes : bytes.sublist(offset),
      allowMalformed: true,
    );
    return parseString(content);
  }

  /// Parses raw CSV [content], handling BOM, CRLF/LF, and `,` or `;` delimiters.
  CsvParseResult parseString(String content) {
    var text = content;
    if (text.startsWith('\uFEFF')) {
      text = text.substring(1);
    }
    text = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (text.endsWith('\n')) {
      text = text.substring(0, text.length - 1);
    }
    if (text.isEmpty) {
      return const CsvParseResult(
        records: <BillingRecord>[],
        droppedRows: <DroppedRow>[],
      );
    }

    final lines = text.split('\n');
    final delimiter = _detectDelimiter(lines);
    var headerEvaluated = false;

    final records = <BillingRecord>[];
    final droppedRows = <DroppedRow>[];

    for (var i = 0; i < lines.length; i++) {
      final rowNumber = i + 1;
      final rawLine = lines[i];

      // Step 1: empty_line
      if (rawLine.trim().isEmpty) {
        droppedRows.add(
          DroppedRow(
            rowNumber: rowNumber,
            reason: DropReason.emptyLine,
            rawLine: rawLine,
          ),
        );
        continue;
      }

      final fields = splitCsvRow(rawLine, delimiter);

      // Skip standard CSV header row if it is the first non-empty row.
      if (!headerEvaluated) {
        headerEvaluated = true;
        if (_isHeaderRow(fields)) {
          continue;
        }
      }

      // Step 2: column_count (!= 6)
      if (fields.length != 6) {
        droppedRows.add(
          DroppedRow(
            rowNumber: rowNumber,
            reason: DropReason.columnCount,
            rawLine: rawLine,
          ),
        );
        continue;
      }

      // Step 3: unknown_type
      final type = BillingType.tryParse(fields[1]);
      if (type == null) {
        droppedRows.add(
          DroppedRow(
            rowNumber: rowNumber,
            reason: DropReason.unknownType,
            rawLine: rawLine,
          ),
        );
        continue;
      }

      // Step 4: bad_datetime
      final timestamp = parseStrictBillingDatetime(fields[0]);
      if (timestamp == null) {
        droppedRows.add(
          DroppedRow(
            rowNumber: rowNumber,
            reason: DropReason.badDatetime,
            rawLine: rawLine,
          ),
        );
        continue;
      }

      // Step 5: bad_number
      final Decimal? durationSec = parseStrictNonNegativeDecimal(fields[3]);
      final Decimal? mb = parseStrictNonNegativeDecimal(fields[4]);
      final Decimal? costSom = parseStrictNonNegativeDecimal(fields[5]);
      if (durationSec == null || mb == null || costSom == null) {
        droppedRows.add(
          DroppedRow(
            rowNumber: rowNumber,
            reason: DropReason.badNumber,
            rawLine: rawLine,
          ),
        );
        continue;
      }

      final rawNumber = fields[2].trim();
      records.add(
        BillingRecord(
          rowNumber: rowNumber,
          timestamp: timestamp,
          formattedDatetime: formatDatetime(timestamp),
          type: type,
          rawNumber: rawNumber,
          normalizedNumber: normalizePhone(rawNumber),
          durationSec: durationSec,
          mb: mb,
          costSom: costSom,
        ),
      );
    }

    return CsvParseResult(
      records: records,
      droppedRows: droppedRows,
    );
  }

  /// Splits a single CSV row by [delimiter] while respecting RFC-4180 quotes.
  List<String> splitCsvRow(String line, String delimiter) {
    final result = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (!inQuotes && ch == delimiter) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }
    result.add(buffer.toString());
    return result;
  }

  String _detectDelimiter(List<String> lines) {
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final commas = _countUnquoted(line, ',');
      final semis = _countUnquoted(line, ';');
      if (semis == 5 || (semis > commas && commas != 5)) {
        return ';';
      }
      return ',';
    }
    return ',';
  }

  int _countUnquoted(String line, String target) {
    var count = 0;
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (!inQuotes && ch == target) {
        count++;
      }
    }
    return count;
  }

  bool _isHeaderRow(List<String> fields) {
    if (fields.length != 6) return false;
    for (var i = 0; i < 6; i++) {
      if (fields[i].trim().toLowerCase() != _expectedHeader[i]) {
        return false;
      }
    }
    return true;
  }
}
