import 'package:decimal/decimal.dart';

final _strictNonNegativeDecimalRegex = RegExp(r'^\d+(?:[.,]\d+)?$');

/// Strictly parses a non-negative decimal string supporting `.` and `,`
/// separators. Rejects `NaN`, `Infinity`, negative numbers, empty strings, and
/// non-numeric text.
Decimal? parseStrictNonNegativeDecimal(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if (!_strictNonNegativeDecimalRegex.hasMatch(trimmed)) {
    return null;
  }
  final normalized = trimmed.replaceAll(',', '.');
  final parsed = Decimal.tryParse(normalized);
  if (parsed == null || parsed < Decimal.zero) {
    return null;
  }
  return parsed;
}

/// Formats [value] with two decimal digits (`0.00`).
String formatSom(Decimal value) {
  return value.toStringAsFixed(2);
}

/// Divides [numerator] by [denominator] into a [Decimal] with exact handling for
/// repeating decimals.
Decimal divToDecimal(
  Decimal numerator,
  Decimal denominator, {
  int scale = 10,
}) {
  return (numerator / denominator).toDecimal(scaleOnInfinitePrecision: scale);
}
