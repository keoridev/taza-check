import 'package:decimal/decimal.dart';

/// Supported billing charge categories in the CSV schema.
enum BillingType {
  call('call'),
  sms('sms'),
  data('data'),
  subscription('subscription'),
  content('content');

  const BillingType(this.wireName);

  final String wireName;

  /// Parses [raw] case-insensitively into a [BillingType], or returns `null`.
  static BillingType? tryParse(String raw) {
    final normalized = raw.trim().toLowerCase();
    for (final value in BillingType.values) {
      if (value.wireName == normalized) {
        return value;
      }
    }
    return null;
  }

  /// Parses [raw] into a [BillingType] or throws [FormatException].
  static BillingType fromWire(String raw) {
    final parsed = tryParse(raw);
    if (parsed == null) {
      throw FormatException('Unknown billing type: $raw');
    }
    return parsed;
  }
}

/// A validated billing detail row parsed from the operator CSV.
class BillingRecord {
  const BillingRecord({
    required this.rowNumber,
    required this.timestamp,
    required this.formattedDatetime,
    required this.type,
    required this.rawNumber,
    required this.normalizedNumber,
    required this.durationSec,
    required this.mb,
    required this.costSom,
  });

  final int rowNumber;
  final DateTime timestamp;
  final String formattedDatetime;
  final BillingType type;
  final String rawNumber;
  final String normalizedNumber;
  final Decimal durationSec;
  final Decimal mb;
  final Decimal costSom;
}
