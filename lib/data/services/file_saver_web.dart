import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

/// Saves or shares a text file on Flutter Web using browser download / Web Share.
Future<String?> saveAndOrShareTextFile({
  required String fileName,
  required String content,
  required String mimeType,
  required bool shareViaSheet,
}) async {
  final bytes = Uint8List.fromList(utf8.encode(content));

  if (shareViaSheet) {
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[
          XFile.fromData(bytes, mimeType: mimeType, name: fileName),
        ],
        fileNameOverrides: <String>[fileName],
        downloadFallbackEnabled: true,
      ),
    );
    return fileName;
  }

  final uri = await FilePicker.saveFile(
    fileName: fileName,
    bytes: bytes,
    mimeType: mimeType,
  );
  return uri?.toString() ?? fileName;
}
