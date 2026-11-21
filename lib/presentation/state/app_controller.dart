import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/engine/anomaly_detector.dart';
import '../../core/engine/billing_analyzer.dart';
import '../../core/engine/claim_generator.dart';
import '../../core/engine/explainer.dart';
import '../../core/engine/llm_service.dart';
import '../../core/engine/tariff_optimizer.dart';
import '../../data/repositories/local_billing_repository.dart';
import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/anomaly.dart';
import '../../domain/entities/family_member.dart';
import '../../domain/entities/tariff_plan.dart';
import '../../domain/repositories/billing_repository.dart';

/// Application state controller coordinating analysis, Family Shield,
/// Tariff Optimizer, optional LLM summaries, and legal claim generation.
class AppController extends ChangeNotifier {
  AppController({
    BillingRepository? repository,
    LlmService? llmService,
    BillingAnalyzer? analyzer,
    AnomalyDetector? detector,
    TariffOptimizer? tariffOptimizer,
    ClaimGenerator? claimGenerator,
  })  : _repository = repository ?? LocalBillingRepository(),
        _llmService = llmService ?? LlmService(),
        _analyzer = analyzer ?? BillingAnalyzer(),
        _detector = detector ?? AnomalyDetector(),
        _tariffOptimizer = tariffOptimizer ?? TariffOptimizer(),
        _claimGenerator = claimGenerator ?? ClaimGenerator();

  final BillingRepository _repository;
  final LlmService _llmService;
  final BillingAnalyzer _analyzer;
  final AnomalyDetector _detector;
  final TariffOptimizer _tariffOptimizer;
  final ClaimGenerator _claimGenerator;

  ThemeMode _themeMode = ThemeMode.dark;
  AppLanguage _language = AppLanguage.ru;
  bool _seniorMode = false;
  int _selectedTabIndex = 0;

  List<FamilyMemberProfile> _familyMembers = <FamilyMemberProfile>[];
  String _activeMemberId = 'me';
  List<FamilyReputationFlag> _reputationFlags = <FamilyReputationFlag>[];

  Set<String> _selectedClaimAnomalyIds = <String>{};
  SubscriberInfo _subscriberInfo = const SubscriberInfo(
    fullName: 'Азамат Токтосунов',
    phone: '+996700112233',
    operatorName: 'O!',
    city: 'г. Бишкек',
  );

  LlmConfig _llmConfig = const LlmConfig();
  String? _activeSummaryText;
  bool _llmUsedLlm = false;
  bool _llmUsedFallback = false;
  List<String> _llmRejectionReasons = <String>[];
  bool _isLoadingLlm = false;
  bool _isBusy = false;
  String? _errorMessage;

  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;
  bool get seniorMode => _seniorMode;
  int get selectedTabIndex => _selectedTabIndex;
  List<FamilyMemberProfile> get familyMembers => _familyMembers;
  String get activeMemberId => _activeMemberId;
  List<FamilyReputationFlag> get reputationFlags => _reputationFlags;
  Set<String> get selectedClaimAnomalyIds => _selectedClaimAnomalyIds;
  SubscriberInfo get subscriberInfo => _subscriberInfo;
  LlmConfig get llmConfig => _llmConfig;
  bool get llmUsedLlm => _llmUsedLlm;
  bool get llmUsedFallback => _llmUsedFallback;
  List<String> get llmRejectionReasons => _llmRejectionReasons;
  bool get isLoadingLlm => _isLoadingLlm;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  FamilyMemberProfile? get activeMember {
    if (_familyMembers.isEmpty) return null;
    for (final m in _familyMembers) {
      if (m.id == _activeMemberId) return m;
    }
    return _familyMembers.first;
  }

  AnalysisResult? get activeResult => activeMember?.result;

  String get currentSummaryText {
    if (_activeSummaryText != null) return _activeSummaryText!;
    final result = activeResult;
    if (result == null) return '';
    return result.summary(_language);
  }

  List<TariffRecommendation> get tariffRecommendations {
    final result = activeResult;
    if (result == null) return const <TariffRecommendation>[];
    return _tariffOptimizer.optimize(result.report);
  }

  List<Anomaly> get selectedClaimAnomalies {
    final result = activeResult;
    if (result == null) return const <Anomaly>[];
    return result.anomalies
        .where((a) => _selectedClaimAnomalyIds.contains(a.id))
        .toList();
  }

  Decimal get selectedClaimRefundTotal =>
      Explainer.calculateTotalOvercharge(selectedClaimAnomalies);

  String get generatedClaimText => _claimGenerator.generateClaim(
        subscriber: _subscriberInfo,
        selectedAnomalies: selectedClaimAnomalies,
        language: _language,
      );

  Decimal get totalFamilySpendSom {
    var total = Decimal.zero;
    for (final m in _familyMembers) {
      if (m.result != null) {
        total += m.result!.report.totalSpendSom;
      }
    }
    return total.round(scale: 2);
  }

  Decimal get totalFamilyOverchargeSom {
    var total = Decimal.zero;
    for (final m in _familyMembers) {
      if (m.result != null) {
        total += m.result!.totalOverchargeSom;
      }
    }
    return total.round(scale: 2);
  }

  Decimal get totalFamilyAnnualLeakSom {
    var total = Decimal.zero;
    for (final m in _familyMembers) {
      if (m.result != null) {
        total += m.result!.annualLeakSom;
      }
    }
    return total.round(scale: 2);
  }

  /// Loads all 5 bundled demo subscriber CSVs into Family Shield.
  Future<void> loadDemoFamily() async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final loaded = await _repository.loadDemoFamily();
      _familyMembers = loaded;
      if (_familyMembers.isNotEmpty &&
          !_familyMembers.any((m) => m.id == _activeMemberId)) {
        _activeMemberId = _familyMembers.first.id;
      }
      _recomputeFamilyDerivedState();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Picks a custom CSV file from disk/browser and assigns it to the active member.
  Future<bool> loadCustomCsvForActiveMember() {
    return loadCustomCsvForMember(_activeMemberId);
  }

  /// Picks a custom CSV file and analyzes it for family member [memberId].
  Future<bool> loadCustomCsvForMember(String memberId) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.pickAndAnalyzeCsv();
      if (result == null) {
        return false;
      }
      if (_familyMembers.isEmpty) {
        _familyMembers = <FamilyMemberProfile>[
          FamilyMemberProfile(
            id: memberId,
            name: 'Я',
            roleLabel: result.sourceName,
            phone: '+996700000000',
            operatorName: 'O!',
            result: result,
          ),
        ];
        _activeMemberId = memberId;
      } else {
        _familyMembers = _familyMembers.map((m) {
          if (m.id == memberId) {
            return m.copyWith(result: result);
          }
          return m;
        }).toList();
      }
      _activeMemberId = memberId;
      _recomputeFamilyDerivedState();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void selectMember(String id) {
    if (_activeMemberId == id) return;
    _activeMemberId = id;
    _syncActiveMemberSelections();
    notifyListeners();
  }

  void setTabIndex(int index) {
    if (_selectedTabIndex == index) return;
    _selectedTabIndex = index;
    notifyListeners();
  }

  void toggleThemeMode() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void toggleSeniorMode([bool? value]) {
    _seniorMode = value ?? !_seniorMode;
    notifyListeners();
  }

  void setLanguage(AppLanguage lang) {
    if (_language == lang) return;
    _language = lang;
    _activeSummaryText = null;
    _llmUsedLlm = false;
    _llmUsedFallback = false;
    _llmRejectionReasons = const <String>[];
    notifyListeners();
  }

  void toggleClaimAnomaly(String id) {
    final updated = Set<String>.from(_selectedClaimAnomalyIds);
    if (!updated.add(id)) {
      updated.remove(id);
    }
    _selectedClaimAnomalyIds = updated;
    notifyListeners();
  }

  void selectAllClaimAnomalies(bool selectAll) {
    final result = activeResult;
    if (result == null) return;
    if (selectAll) {
      _selectedClaimAnomalyIds = result.anomalies
          .where((a) => a.type != AnomalyType.daySpike)
          .map((a) => a.id)
          .toSet();
    } else {
      _selectedClaimAnomalyIds = <String>{};
    }
    notifyListeners();
  }

  void updateSubscriberInfo({
    String? fullName,
    String? phone,
    String? operatorName,
    String? city,
  }) {
    _subscriberInfo = _subscriberInfo.copyWith(
      fullName: fullName,
      phone: phone,
      operatorName: operatorName,
      city: city,
    );
    notifyListeners();
  }

  Future<void> runLlmSummary(LlmConfig config) async {
    final result = activeResult;
    if (result == null) return;
    _llmConfig = config;
    _isLoadingLlm = true;
    notifyListeners();
    try {
      final summaryResult = await _llmService.generateSummary(
        result,
        config: config,
        language: _language,
      );
      _activeSummaryText = summaryResult.text;
      _llmUsedLlm = summaryResult.usedLlm;
      _llmUsedFallback = summaryResult.usedFallback;
      _llmRejectionReasons = summaryResult.rejectionReasons;
    } finally {
      _isLoadingLlm = false;
      notifyListeners();
    }
  }

  Future<String?> exportAnomaliesJson({bool shareViaSheet = false}) async {
    final result = activeResult;
    if (result == null) return null;
    return _repository.exportTextFile(
      fileName: 'anomalies.json',
      content: _analyzer.encodeAnomaliesJson(result.anomalies),
      mimeType: 'application/json',
      shareViaSheet: shareViaSheet,
    );
  }

  Future<String?> exportDroppedRowsCsv({bool shareViaSheet = false}) async {
    final result = activeResult;
    if (result == null) return null;
    return _repository.exportTextFile(
      fileName: 'dropped_rows.csv',
      content: _analyzer.encodeDroppedRowsCsv(result.droppedRows),
      mimeType: 'text/csv',
      shareViaSheet: shareViaSheet,
    );
  }

  Future<String?> exportClaimTxt({bool shareViaSheet = false}) async {
    if (activeResult == null) return null;
    return _repository.exportTextFile(
      fileName: 'claim.txt',
      content: generatedClaimText,
      mimeType: 'text/plain',
      shareViaSheet: shareViaSheet,
    );
  }

  void _recomputeFamilyDerivedState() {
    _reputationFlags = _detector.detectFamilyReputation(_familyMembers);
    _syncActiveMemberSelections();
  }

  void _syncActiveMemberSelections() {
    final member = activeMember;
    if (member != null) {
      _subscriberInfo = _subscriberInfo.copyWith(
        fullName: member.roleLabel,
        phone: member.phone,
        operatorName: member.operatorName,
      );
    }
    final result = activeResult;
    if (result != null) {
      _selectedClaimAnomalyIds = result.anomalies
          .where((a) => a.type != AnomalyType.daySpike)
          .map((a) => a.id)
          .toSet();
    } else {
      _selectedClaimAnomalyIds = <String>{};
    }
    _activeSummaryText = null;
    _llmUsedLlm = false;
    _llmUsedFallback = false;
    _llmRejectionReasons = const <String>[];
  }
}
