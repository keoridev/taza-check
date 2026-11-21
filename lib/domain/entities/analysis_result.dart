import 'package:decimal/decimal.dart';

import '../../core/constants/app_strings.dart';
import 'anomaly.dart';
import 'billing_record.dart';
import 'dropped_row.dart';
import 'financial_report.dart';

/// Complete output of analyzing a single subscriber billing CSV.
class AnalysisResult {
  const AnalysisResult({
    required this.sourceName,
    required this.records,
    required this.droppedRows,
    required this.report,
    required this.anomalies,
    required this.totalOverchargeSom,
    required this.annualLeakSom,
    required this.summaryRu,
    required this.summaryKy,
    this.summaryEn = '',
  });

  final String sourceName;
  final List<BillingRecord> records;
  final List<DroppedRow> droppedRows;
  final FinancialReport report;
  final List<Anomaly> anomalies;
  final Decimal totalOverchargeSom;
  final Decimal annualLeakSom;
  final String summaryRu;
  final String summaryKy;
  final String summaryEn;

  String summary(AppLanguage language) => switch (language) {
        AppLanguage.ru => summaryRu,
        AppLanguage.ky => summaryKy,
        AppLanguage.en => summaryEn.isNotEmpty ? summaryEn : summaryRu,
      };
}
