import 'package:billing_shield/core/constants/app_strings.dart';
import 'package:billing_shield/core/engine/claim_generator.dart';
import 'package:billing_shield/core/engine/tariff_optimizer.dart';
import 'package:billing_shield/domain/entities/anomaly.dart';
import 'package:billing_shield/domain/entities/billing_record.dart';
import 'package:billing_shield/domain/entities/financial_report.dart';
import 'package:decimal/decimal.dart';
import 'package:test/test.dart';

void main() {
  group('ClaimGenerator', () {
    final generator = ClaimGenerator();
    final sampleAnomalies = <Anomaly>[
      Anomaly(
        id: '1',
        datetime: '2026-09-10 02:15:30',
        type: AnomalyType.nightCharge,
        reason: 'Ночное списание 4545: 15.00 сом',
        number: '4545',
        costSom: Decimal.parse('15.00'),
        overchargeSom: Decimal.parse('15.00'),
        rowNumber: 12,
        explanationRu: 'Ночное списание 15.00 сом',
        explanationKy: 'Түнкү төлөм 15.00 сом',
      ),
      Anomaly(
        id: '2',
        datetime: '2026-09-22 14:20:00',
        type: AnomalyType.internationalRate,
        reason: 'Международный звонок +905321234567',
        number: '+905321234567',
        costSom: Decimal.parse('250.00'),
        overchargeSom: Decimal.parse('150.00'),
        rowNumber: 25,
        explanationRu: 'Международный звонок',
        explanationKy: 'Эл аралык чалуу',
      ),
    ];

    const sub = SubscriberInfo(
      fullName: 'Азамат Токтосунов',
      phone: '+996700112233',
      operatorName: 'O!',
    );

    test('generates RU legal claim citing KG Consumer Protection Law and exact refund total', () {
      final claim = generator.generateClaim(
        subscriber: sub,
        selectedAnomalies: sampleAnomalies,
        language: AppLanguage.ru,
        date: DateTime.utc(2026, 10, 1),
      );

      expect(claim, contains('О защите прав потребителей'));
      expect(claim, contains('165.00 сом'));
      expect(claim, contains('+996700112233'));
      expect(claim, contains('2026-10-01'));
    });

    test('generates KY legal claim citing Kyrgyz Consumer Protection Law', () {
      final claim = generator.generateClaim(
        subscriber: sub,
        selectedAnomalies: sampleAnomalies,
        language: AppLanguage.ky,
        date: DateTime.utc(2026, 10, 1),
      );

      expect(claim, contains('Керектөөчүлөрдүн укуктарын коргоо жөнүндө'));
      expect(claim, contains('165.00 сом'));
    });

    test('generates EN legal claim citing Kyrgyz Republic Consumer Protection Law', () {
      final claim = generator.generateClaim(
        subscriber: sub,
        selectedAnomalies: sampleAnomalies,
        language: AppLanguage.en,
        date: DateTime.utc(2026, 10, 1),
      );

      expect(claim, contains('On Consumer Rights Protection'));
      expect(claim, contains('165.00 KGS'));
      expect(claim, contains('+996700112233'));
    });
  });

  group('TariffOptimizer', () {
    test('recommends cheapest plan and computes exact yearly savings in Decimal', () {
      final optimizer = TariffOptimizer();
      final report = FinancialReport(
        totalSpendSom: Decimal.parse('600.00'),
        byCategory: {
          for (final t in BillingType.values) t: Decimal.zero,
        },
        byDay: const [],
        topNumbers: const [],
        totalCallMinutes: Decimal.fromInt(40),
        totalDataMb: Decimal.fromInt(10240), // 10 GB
        totalSmsCount: 15,
        subscriptionSpendSom: Decimal.zero,
        periodDays: 30,
      );

      final recs = optimizer.optimize(report);
      expect(recs, isNotEmpty);
      final best = recs.first;
      expect(best.plan.name, 'СуперВыгодный 190');
      expect(best.estimatedMonthlyCostSom, Decimal.parse('190.00'));
      expect(best.monthlySavingsSom, Decimal.parse('410.00'));
      expect(best.yearlySavingsSom, Decimal.parse('4920.00'));
    });
  });
}
