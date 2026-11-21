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
      summaryEn: summaries.en,
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
    final tr = AppStrings.tr;
    final cur = AppStrings.currency(language);
    final buffer = StringBuffer()
      ..writeln('# ${AppStrings.appTitle(language)} — ${result.sourceName}')
      ..writeln()
      ..writeln(result.summary(language))
      ..writeln()
      ..writeln(
        tr(
          language,
          ru: '## Ключевые показатели',
          ky: '## Негизги көрсөткүчтөр',
          en: '## Key metrics',
        ),
      )
      ..writeln(
        '- ${tr(language, ru: "Всего потрачено", ky: "Жалпы чыгым", en: "Total spent")}: **${formatSom(result.report.totalSpendSom)} $cur**',
      )
      ..writeln(
        '- ${tr(language, ru: "Возможная переплата", ky: "Мүмкүн болгон ашыкча төлөм", en: "Estimated overcharge")}: **${formatSom(result.totalOverchargeSom)} $cur**',
      )
      ..writeln(
        '- ${tr(language, ru: "Прогноз утечки за год (подписки × 12)", ky: "Жылдык жоготуу божомолу", en: "Annual leak forecast (subscriptions × 12)")}: **${formatSom(result.annualLeakSom)} $cur**',
      )
      ..writeln(
        '- ${tr(language, ru: "Принято строк / Отброшено битых", ky: "Кабыл алынган / Бузулган саптар", en: "Accepted rows / Dropped malformed rows")}: **${result.records.length} / ${result.droppedRows.length}**',
      )
      ..writeln()
      ..writeln(
        tr(
          language,
          ru: '## Расходы по категориям',
          ky: '## Категориялар боюнча чыгымдар',
          en: '## Spend by category',
        ),
      );

    for (final type in BillingType.values) {
      final sum = result.report.byCategory[type] ?? Decimal.zero;
      buffer.writeln(
        '- ${AppStrings.categoryLabel(type, language)} (`${type.wireName}`): ${formatSom(sum)} $cur',
      );
    }

    buffer
      ..writeln()
      ..writeln(
        tr(
          language,
          ru: '## Топ-5 дорогих номеров',
          ky: '## Эң кымбат 5 номер',
          en: '## Top-5 numbers by spend',
        ),
      );
    if (result.report.topNumbers.isEmpty) {
      buffer.writeln(
        tr(language, ru: '- Нет данных', ky: '- Маалымат жок', en: '- No data'),
      );
    } else {
      for (final item in result.report.topNumbers) {
        buffer.writeln(
          '- `${item.normalizedNumber}`: ${formatSom(item.totalSom)} $cur (${item.count})',
        );
      }
    }

    buffer
      ..writeln()
      ..writeln(
        tr(
          language,
          ru: '## Выявленные аномалии (${result.anomalies.length})',
          ky: '## Аныкталган аномалиялар (${result.anomalies.length})',
          en: '## Detected anomalies (${result.anomalies.length})',
        ),
      );
    if (result.anomalies.isEmpty) {
      buffer.writeln(
        tr(
          language,
          ru: '- Аномалий не обнаружено.',
          ky: '- Аномалия табылган жок.',
          en: '- No anomalies detected.',
        ),
      );
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
