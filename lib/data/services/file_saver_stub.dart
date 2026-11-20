/// Fallback stub when neither `dart:io` nor `dart:js_interop` is available.
Future<String?> saveAndOrShareTextFile({
  required String fileName,
  required String content,
  required String mimeType,
  required bool shareViaSheet,
}) {
  throw UnsupportedError('Platform file saving is not supported.');
}
