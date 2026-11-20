import 'dart:io';

import 'package:billing_shield/core/constants/app_strings.dart';
import 'package:billing_shield/core/engine/billing_analyzer.dart';

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    stderr.writeln(
      'Usage: dart run bin/analyze.dart <path_to_csv> [--out-dir <dir>] [--lang ru|ky]',
    );
    exitCode = 1;
    return;
  }

  String? csvPath;
  var outDirPath = Directory.current.path;
  var language = AppLanguage.ru;

  for (var i = 0; i < arguments.length; i++) {
    final arg = arguments[i];
    if (arg == '--out-dir' && i + 1 < arguments.length) {
      outDirPath = arguments[++i];
    } else if (arg == '--lang' && i + 1 < arguments.length) {
      final rawLang = arguments[++i].toLowerCase();
      language = rawLang == 'ky' ? AppLanguage.ky : AppLanguage.ru;
    } else if (!arg.startsWith('--') && csvPath == null) {
      csvPath = arg;
    }
  }

  if (csvPath == null) {
    stderr.writeln('Error: missing <path_to_csv> argument.');
    exitCode = 1;
    return;
  }

  final inputFile = File(csvPath);
  if (!inputFile.existsSync()) {
    stderr.writeln('Error: CSV file not found at "$csvPath".');
    exitCode = 1;
    return;
  }

  final outDir = Directory(outDirPath);
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final fileName = inputFile.uri.pathSegments.lastWhere(
    (s) => s.isNotEmpty,
    orElse: () => 'billing.csv',
  );
  final bytes = inputFile.readAsBytesSync();

  final analyzer = BillingAnalyzer();
  final result = analyzer.analyzeCsvBytes(bytes, sourceName: fileName);

  final anomaliesFile = File(
    '${outDir.path}${Platform.pathSeparator}anomalies.json',
  );
  anomaliesFile.writeAsStringSync('${analyzer.encodeAnomaliesJson(result.anomalies)}\n');

  final droppedFile = File(
    '${outDir.path}${Platform.pathSeparator}dropped_rows.csv',
  );
  droppedFile.writeAsStringSync(analyzer.encodeDroppedRowsCsv(result.droppedRows));

  stdout.writeln(analyzer.buildMarkdownReport(result, language: language));
}
