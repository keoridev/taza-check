import 'file_saver.dart';

/// Exports `anomalies.json`, `dropped_rows.csv`, and `claim.txt` across
/// Android, Windows Desktop, and Web.
class ExportService {
  /// Saves or shares arbitrary text [content] under [fileName].
  Future<String?> exportText({
    required String fileName,
    required String content,
    required String mimeType,
    bool shareViaSheet = false,
  }) {
    return saveAndOrShareTextFile(
      fileName: fileName,
      content: content,
      mimeType: mimeType,
      shareViaSheet: shareViaSheet,
    );
  }
}
