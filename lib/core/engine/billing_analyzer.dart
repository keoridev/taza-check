import 'dart:convert';

import 'package:decimal/decimal.dart';

import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/anomaly.dart';
import '../../domain/entities/billing_record.dart';
import '../../domain/entities/dropped_row.dart';
import '../constants/app_strings.dart';
import '../utils/decimal_utils.dart';
import 'anomaly_detector.dart';
import 'csv_parser.dart';
import 'explainer.dart';
import 'report_builder.dart';

/// Unified pure-Dart facade running parsing, aggregation, anomaly detection,
/// and Jury-compatible export generation.
class BillingAnalyzer {
  BillingAnalyzer({
    CsvParser? parser,
    ReportBuilder? reportBuilder,
    AnomalyDetector? detector,
  })  : _parser = parser ?? CsvParser(),
        _reportBuilder = reportBuilder ?? ReportBuilder(),
        _detector = detector ?? AnomalyDetector();

  final CsvParser _parser;
  final ReportBuilder _reportBuilder;
  final AnomalyDetector _detector;

  /// Analyzes raw UTF-8 CSV bytes.
  AnalysisResult analyzeCsvBytes(
    List<int> bytes, {
    String sourceName = 'billing.csv',
  }) {
    final parsed = _parser.parseBytes(bytes);
    return _finalize(parsed, sourceName);
  }

  /// Analyzes a CSV string.
  AnalysisResult analyzeCsvString(
    String csvContent, {
    String sourceName = 'billing.csv',
  }) {
    final parsed = _parser.parseString(csvContent);
    return _finalize(parsed, sourceName);
  }

  AnalysisResult _finalize(CsvParseResult parsed, String sourceName) {
    final report = _reportBuilder.build(parsed.records);
    final anomalies = _detector.detect(parsed.records, report);
    final totalOvercharge = Explainer.calculateTotalOvercharge(anomalies);

    // Annual leak forecast: normalized monthly (30d) subscriptions + content * 12.
    final periodDays = report.periodDays > 0 ? report.periodDays : 30;
    final monthlySubSpend = divToDecimal(
      report.subscriptionSpendSom * Decimal.fromInt(30),
      Decimal.fromInt(periodDays),
      scale: 4,
    );
    final annualLeak = (monthlySubSpend * Decimal.fromInt(12)).round(scale: 2);

    final summaries = Explainer.buildDeterministicSummaries(
      sourceName: sourceName,
      report: report,
      anomalies: anomalies,
      droppedRows: parsed.droppedRows,
      totalOverchargeSom: totalOvercharge,
      annualLeakSom: annualLeak,
    );

    return AnalysisResult(
      sourceName: sourceName,
      records: parsed.records,
      droppedRows: parsed.droppedRows,
      report: report,
      anomalies: anomalies,
      totalOverchargeSom: totalOvercharge,
      annualLeakSom: annualLeak,
      summaryRu: summaries.ru,
      summaryKy: summaries.ky,
    );
  }

  /// Encodes [anomalies] strictly to the Task 4 Jury JSON schema.
  String encodeAnomaliesJson(List<Anomaly> anomalies) {
    final payload = anomalies.map((a) => a.toJuryJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Encodes skipped rows into CSV format for `dropped_rows.csv`.
  String encodeDroppedRowsCsv(List<DroppedRow> rows) {
    final buffer = StringBuffer('row_number,reason,raw_line\n');
    for (final row in rows) {
      buffer.writeln(row.toCsvRow());
    }
    return buffer.toString();
  }

  /// Builds a clean Markdown summary report for CLI and export use.
  String buildMarkdownReport(
    AnalysisResult result, {
    AppLanguage language = AppLanguage.ru,
  }) {
    final isRu = language == AppLanguage.ru;
    final buffer = StringBuffer()
      ..writeln('# ${AppStrings.appTitle(language)} — ${result.sourceName}')
      ..writeln()
      ..writeln(
        isRu ? result.summaryRu : result.summaryKy,
      )
      ..writeln()
      ..writeln(isRu ? '## Ключевые показатели' : '## Негизги көрсөткүчтөр')
      ..writeln(
        '- ${isRu ? "Всего потрачено" : "Жалпы чыгым"}: **${formatSom(result.report.totalSpendSom)} сом**',
      )
      ..writeln(
        '- ${isRu ? "Возможная переплата" : "Мүмкүн болгон ашыкча төлөм"}: **${formatSom(result.totalOverchargeSom)} сом**',
      )
      ..writeln(
        '- ${isRu ? "Прогноз утечки за год (подписки × 12)" : "Жылдык жоготуу божомолу"}: **${formatSom(result.annualLeakSom)} сом**',
      )
      ..writeln(
        '- ${isRu ? "Принято строк / Отброшено битых" : "Кабыл алынган / Бузулган саптар"}: **${result.records.length} / ${result.droppedRows.length}**',
      )
      ..writeln()
      ..writeln(isRu ? '## Расходы по категориям' : '## Категориялар боюнча чыгымдар');

    for (final type in BillingType.values) {
      final sum = result.report.byCategory[type] ?? Decimal.zero;
      buffer.writeln(
        '- ${AppStrings.categoryLabel(type, language)} (`${type.wireName}`): ${formatSom(sum)} сом',
      );
    }

    buffer
      ..writeln()
      ..writeln(isRu ? '## Топ-5 дорогих номеров' : '## Эң кымбат 5 номер');
    if (result.report.topNumbers.isEmpty) {
      buffer.writeln(isRu ? '- Нет данных' : '- Маалымат жок');
    } else {
      for (final item in result.report.topNumbers) {
        buffer.writeln(
          '- `${item.normalizedNumber}`: ${formatSom(item.totalSom)} сом (${item.count})',
        );
      }
    }

    buffer
      ..writeln()
      ..writeln(
        isRu
            ? '## Выявленные аномалии (${result.anomalies.length})'
            : '## Аныкталган аномалиялар (${result.anomalies.length})',
      );
    if (result.anomalies.isEmpty) {
      buffer.writeln(isRu ? '- Аномалий не обнаружено.' : '- Аномалия табылган жок.');
    } else {
      for (final a in result.anomalies) {
        buffer.writeln(
          '- **${a.type.wireName}** | `${a.datetime}` | ${a.reason}',
        );
      }
    }

    return buffer.toString();
  }
}
