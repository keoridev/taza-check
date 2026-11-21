import 'package:decimal/decimal.dart';

import '../../core/constants/app_strings.dart';

/// Mandatory anomaly detector categories required by Task 4.
enum AnomalyType {
  daySpike('day_spike'),
  nightCharge('night_charge'),
  newSubscription('new_subscription'),
  duplicateCharge('duplicate_charge'),
  internationalRate('international_rate');

  const AnomalyType(this.wireName);

  final String wireName;
}

/// Detected billing anomaly with Jury-compatible JSON fields and rich UI metadata.
class Anomaly {
  const Anomaly({
    required this.id,
    required this.datetime,
    required this.type,
    required this.reason,
    required this.costSom,
    required this.overchargeSom,
    required this.explanationRu,
    required this.explanationKy,
    this.explanationEn = '',
    this.number,
    this.rowNumber,
    this.ussdHint,
    this.zScore,
    this.baselineMeanSom,
  });

  final String id;
  final String datetime;
  final AnomalyType type;
  final String reason;
  final String? number;
  final Decimal costSom;
  final Decimal overchargeSom;
  final int? rowNumber;
  final String? ussdHint;
  final String explanationRu;
  final String explanationKy;
  final String explanationEn;
  final double? zScore;
  final Decimal? baselineMeanSom;

  String explanation(AppLanguage language) => switch (language) {
        AppLanguage.ru => explanationRu,
        AppLanguage.ky => explanationKy,
        AppLanguage.en =>
          explanationEn.isNotEmpty ? explanationEn : explanationRu,
      };

  /// Exports the schema expected by automated jury checks (`CLARIFICATIONS_RU.md` §4).
  Map<String, dynamic> toJuryJson() {
    final juryDatetime = type == AnomalyType.daySpike && datetime.length == 10
        ? '$datetime 00:00:00'
        : datetime;
    final juryAmount = type == AnomalyType.daySpike
        ? (costSom - (baselineMeanSom ?? Decimal.zero)).round(scale: 2)
        : overchargeSom.round(scale: 2);
    return <String, dynamic>{
      'datetime': juryDatetime,
      'type': type.wireName,
      'anomaly_type': type.wireName,
      'amount_som': juryAmount.toDouble(),
      'reason': reason,
    };
  }
}
