final _isoDatetimeRegex = RegExp(r'^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$');
final _dotDatetimeRegex = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4}) (\d{2}):(\d{2}):(\d{2})$');

/// Returns the number of calendar days in [month] of [year].
int daysInMonth(int year, int month) {
  switch (month) {
    case 1:
    case 3:
    case 5:
    case 7:
    case 8:
    case 10:
    case 12:
      return 31;
    case 4:
    case 6:
    case 9:
    case 11:
      return 30;
    case 2:
      final isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeap ? 29 : 28;
    default:
      return 0;
  }
}

/// Strictly parses `YYYY-MM-DD HH:MM:SS` or `DD.MM.YYYY HH:MM:SS` into a
/// UTC-normalized wall-clock [DateTime], rejecting invalid calendar dates such
/// as `2026-09-31` or `2026-02-29`.
DateTime? parseStrictBillingDatetime(String raw) {
  final trimmed = raw.trim();
  int year;
  int month;
  int day;
  int hour;
  int minute;
  int second;

  final isoMatch = _isoDatetimeRegex.firstMatch(trimmed);
  if (isoMatch != null) {
    year = int.parse(isoMatch.group(1)!);
    month = int.parse(isoMatch.group(2)!);
    day = int.parse(isoMatch.group(3)!);
    hour = int.parse(isoMatch.group(4)!);
    minute = int.parse(isoMatch.group(5)!);
    second = int.parse(isoMatch.group(6)!);
  } else {
    final dotMatch = _dotDatetimeRegex.firstMatch(trimmed);
    if (dotMatch == null) {
      return null;
    }
    day = int.parse(dotMatch.group(1)!);
    month = int.parse(dotMatch.group(2)!);
    year = int.parse(dotMatch.group(3)!);
    hour = int.parse(dotMatch.group(4)!);
    minute = int.parse(dotMatch.group(5)!);
    second = int.parse(dotMatch.group(6)!);
  }

  if (year < 1900 || year > 2100) return null;
  if (month < 1 || month > 12) return null;
  final maxDay = daysInMonth(year, month);
  if (day < 1 || day > maxDay) return null;
  if (hour < 0 || hour > 23) return null;
  if (minute < 0 || minute > 59) return null;
  if (second < 0 || second > 59) return null;

  return DateTime.utc(year, month, day, hour, minute, second);
}

String _pad2(int value) => value < 10 ? '0$value' : '$value';

/// Formats [dt] as `YYYY-MM-DD HH:MM:SS`.
String formatDatetime(DateTime dt) {
  return '${formatDate(dt)} ${_pad2(dt.hour)}:${_pad2(dt.minute)}:${_pad2(dt.second)}';
}

/// Formats [dt] as `YYYY-MM-DD`.
String formatDate(DateTime dt) {
  return '${dt.year.toString().padLeft(4, '0')}-${_pad2(dt.month)}-${_pad2(dt.day)}';
}
