import 'package:decimal/decimal.dart';

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
  final double? zScore;
  final Decimal? baselineMeanSom;

  /// Exports strictly the schema expected by automated jury checks.
  Map<String, dynamic> toJuryJson() => <String, dynamic>{
        'datetime': datetime,
        'type': type.wireName,
        'reason': reason,
      };
}
