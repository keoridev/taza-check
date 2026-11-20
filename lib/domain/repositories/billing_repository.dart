import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/family_member.dart';

/// Abstraction for loading demo datasets, user CSV files, and exporting reports.
abstract class BillingRepository {
  /// Loads and analyzes all 5 bundled demo subscriber CSVs.
  Future<List<FamilyMemberProfile>> loadDemoFamily();

  /// Opens a cross-platform CSV file picker and analyzes the selected file.
  /// Returns `null` if the user cancels.
  Future<AnalysisResult?> pickAndAnalyzeCsv();

  /// Exports or shares a generated text artifact (`claim.txt`, `anomalies.json`,
  /// `dropped_rows.csv`). Returns a status message or saved target path/URI.
  Future<String?> exportTextFile({
    required String fileName,
    required String content,
    required String mimeType,
    bool shareViaSheet = false,
  });
}
