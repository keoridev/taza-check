final _stripRegex = RegExp(r'[\s\-()]');
final _shortCodeRegex = RegExp(r'^\d{3,6}$');
final _kgNoPlusRegex = RegExp(r'^996\d{6,}$');
final _kg00Regex = RegExp(r'^00996\d{6,}$');
final _kgLocalZeroRegex = RegExp(r'^0[2-9]\d{8}$');
final _intlRegex = RegExp(r'^\+(?!996)\d+$');
final _nonDigitsRegex = RegExp(r'\D');

/// Trims [raw] and removes spaces, hyphens, and parentheses.
String cleanPhone(String raw) {
  return raw.trim().replaceAll(_stripRegex, '');
}

/// Returns `true` strictly when [raw] represents a 3-to-6 digit short code
/// with no leading `+`.
bool isShortCode(String raw) {
  final cleaned = cleanPhone(raw);
  return _shortCodeRegex.hasMatch(cleaned);
}

/// Normalizes Kyrgyz and international phone numbers consistently.
///
/// Merges `996...`, `00996...`, and local `0XXXXXXXXX` formats into `+996...`
/// without colliding with 3-to-6 digit short codes.
String normalizePhone(String raw) {
  final cleaned = cleanPhone(raw);
  if (cleaned.isEmpty) {
    return '';
  }
  if (_kgNoPlusRegex.hasMatch(cleaned)) {
    return '+$cleaned';
  }
  if (_kg00Regex.hasMatch(cleaned)) {
    return '+${cleaned.substring(2)}';
  }
  if (_kgLocalZeroRegex.hasMatch(cleaned)) {
    return '+996${cleaned.substring(1)}';
  }
  if (cleaned.startsWith('+')) {
    final digits = cleaned.substring(1).replaceAll(_nonDigitsRegex, '');
    return digits.isEmpty ? '' : '+$digits';
  }
  return cleaned;
}

/// Returns `true` when a normalized number is international (`+...` excluding `+996`).
bool isInternational(String normalized) {
  return _intlRegex.hasMatch(normalized);
}
