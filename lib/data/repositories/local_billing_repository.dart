import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import '../../core/engine/billing_analyzer.dart';
import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/family_member.dart';
import '../../domain/repositories/billing_repository.dart';
import '../services/export_service.dart';

/// Local repository loading bundled demo CSV assets and user-picked CSV files.
class LocalBillingRepository implements BillingRepository {
  LocalBillingRepository({
    BillingAnalyzer? analyzer,
    ExportService? exportService,
    AssetBundle? bundle,
  })  : _analyzer = analyzer ?? BillingAnalyzer(),
        _exportService = exportService ?? ExportService(),
        _bundle = bundle ?? rootBundle;

  final BillingAnalyzer _analyzer;
  final ExportService _exportService;
  final AssetBundle _bundle;

  static const List<({
    String id,
    String name,
    String roleLabel,
    String phone,
    String operatorName,
    String assetPath,
    String fileName,
  })> _demoSpecs = [
    (
      id: 'me',
      name: 'Я',
      roleLabel: 'Азамат (владелец)',
      phone: '+996700112233',
      operatorName: 'O!',
      assetPath: 'assets/demo/billing_01.csv',
      fileName: 'billing_01.csv',
    ),
    (
      id: 'mom',
      name: 'Мама',
      roleLabel: 'Гульнара',
      phone: '+996550223344',
      operatorName: 'Mega',
      assetPath: 'assets/demo/billing_02.csv',
      fileName: 'billing_02.csv',
    ),
    (
      id: 'dad',
      name: 'Папа',
      roleLabel: 'Бакыт',
      phone: '+996555889900',
      operatorName: 'Mega',
      assetPath: 'assets/demo/billing_03.csv',
      fileName: 'billing_03.csv',
    ),
    (
      id: 'grandma',
      name: 'Бабушка',
      roleLabel: 'Айша',
      phone: '+996702334455',
      operatorName: 'O!',
      assetPath: 'assets/demo/billing_04.csv',
      fileName: 'billing_04.csv',
    ),
    (
      id: 'brother',
      name: 'Брат',
      roleLabel: 'Тимур',
      phone: '+996777112233',
      operatorName: 'Beeline',
      assetPath: 'assets/demo/billing_05.csv',
      fileName: 'billing_05.csv',
    ),
  ];

  @override
  Future<List<FamilyMemberProfile>> loadDemoFamily() async {
    final profiles = <FamilyMemberProfile>[];
    for (final spec in _demoSpecs) {
      final data = await _bundle.load(spec.assetPath);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final result = _analyzer.analyzeCsvBytes(
        bytes,
        sourceName: spec.fileName,
      );
      profiles.add(
        FamilyMemberProfile(
          id: spec.id,
          name: spec.name,
          roleLabel: spec.roleLabel,
          phone: spec.phone,
          operatorName: spec.operatorName,
          result: result,
        ),
      );
    }
    return profiles;
  }

  @override
  Future<AnalysisResult?> pickAndAnalyzeCsv() async {
    final picked = await FilePicker.pickFile(
      dialogTitle: 'Выберите CSV детализацию оператора',
      type: FileType.custom,
      allowedExtensions: const <String>['csv', 'txt'],
    );
    if (picked == null) {
      return null;
    }
    final bytes = await picked.readAsBytes();
    return _analyzer.analyzeCsvBytes(bytes, sourceName: picked.name);
  }

  @override
  Future<String?> exportTextFile({
    required String fileName,
    required String content,
    required String mimeType,
    bool shareViaSheet = false,
  }) {
    return _exportService.exportText(
      fileName: fileName,
      content: content,
      mimeType: mimeType,
      shareViaSheet: shareViaSheet,
    );
  }
}
