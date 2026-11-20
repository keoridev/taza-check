import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Saves or shares a text file on Windows Desktop and Android using native
/// file dialogs or the OS share sheet.
Future<String?> saveAndOrShareTextFile({
  required String fileName,
  required String content,
  required String mimeType,
  required bool shareViaSheet,
}) async {
  final bytes = Uint8List.fromList(utf8.encode(content));

  if (shareViaSheet) {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(file.path, mimeType: mimeType)],
        fileNameOverrides: <String>[fileName],
      ),
    );
    return file.path;
  }

  final savedUri = await FilePicker.saveFile(
    dialogTitle: fileName,
    fileName: fileName,
    bytes: bytes,
    mimeType: mimeType,
  );
  if (savedUri == null) {
    return null;
  }
  return savedUri.scheme == 'file' ? savedUri.toFilePath() : savedUri.toString();
}
