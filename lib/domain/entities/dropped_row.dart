/// Validation failure reasons following the mandatory 5-step cascade.
enum DropReason {
  emptyLine('empty_line'),
  columnCount('column_count'),
  unknownType('unknown_type'),
  badDatetime('bad_datetime'),
  badNumber('bad_number');

  const DropReason(this.wireName);

  final String wireName;
}

/// A corrupted or malformed CSV row skipped during fault-tolerant parsing.
class DroppedRow {
  const DroppedRow({
    required this.rowNumber,
    required this.reason,
    required this.rawLine,
  });

  final int rowNumber;
  final DropReason reason;
  final String rawLine;

  /// Formats this record as a valid RFC-4180 CSV row for `dropped_rows.csv`.
  String toCsvRow() {
    final escaped = rawLine.replaceAll('"', '""');
    return '$rowNumber,${reason.wireName},"$escaped"';
  }
}
