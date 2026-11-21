import 'package:decimal/decimal.dart';

import '../../core/constants/app_strings.dart';
import 'analysis_result.dart';

/// Profile of a family member protected under Family Shield.
class FamilyMemberProfile {
  const FamilyMemberProfile({
    required this.id,
    required this.name,
    required this.roleLabel,
    required this.phone,
    required this.operatorName,
    this.result,
  });

  final String id;
  final String name;
  final String roleLabel;
  final String phone;
  final String operatorName;
  final AnalysisResult? result;

  /// Returns a copy of this profile with an updated [result].
  FamilyMemberProfile copyWith({
    String? name,
    String? roleLabel,
    String? phone,
    String? operatorName,
    AnalysisResult? result,
  }) {
    return FamilyMemberProfile(
      id: id,
      name: name ?? this.name,
      roleLabel: roleLabel ?? this.roleLabel,
      phone: phone ?? this.phone,
      operatorName: operatorName ?? this.operatorName,
      result: result ?? this.result,
    );
  }
}

/// Cross-account reputation flag for short codes draining multiple family members.
class FamilyReputationFlag {
  const FamilyReputationFlag({
    required this.shortCode,
    required this.affectedMemberNames,
    required this.totalFamilyLossSom,
    required this.chargeCount,
    required this.ussdHint,
    required this.explanationRu,
    required this.explanationKy,
    this.explanationEn = '',
  });

  final String shortCode;
  final List<String> affectedMemberNames;
  final Decimal totalFamilyLossSom;
  final int chargeCount;
  final String ussdHint;
  final String explanationRu;
  final String explanationKy;
  final String explanationEn;

  String explanation(AppLanguage language) => switch (language) {
        AppLanguage.ru => explanationRu,
        AppLanguage.ky => explanationKy,
        AppLanguage.en =>
          explanationEn.isNotEmpty ? explanationEn : explanationRu,
      };
}
