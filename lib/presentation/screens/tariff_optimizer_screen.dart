import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/decimal_utils.dart';
import '../../domain/entities/tariff_plan.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';

/// Smart Kyrgyz operator tariff optimizer (`Подбор тарифа`).
class TariffOptimizerScreen extends StatefulWidget {
  const TariffOptimizerScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  State<TariffOptimizerScreen> createState() => _TariffOptimizerScreenState();
}

class _TariffOptimizerScreenState extends State<TariffOptimizerScreen> {
  String _selectedOperator = 'ALL';

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final result = controller.activeResult;
    final isRu = controller.language == AppLanguage.ru;

    if (result == null) {
      return Center(
        child: Text(isRu ? 'Нет данных для подбора' : 'Маалымат жок'),
      );
    }

    final recs = controller.tariffRecommendations;
    final filtered = _selectedOperator == 'ALL'
        ? recs
        : recs.where((r) => r.plan.operatorName == _selectedOperator).toList();
    final best = recs.isNotEmpty ? recs.first : null;
    final report = result.report;
    final gbUsed = divToDecimal(
      report.totalDataMb,
      Decimal.fromInt(1024),
      scale: 2,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRu
                      ? 'Фактическое потребление за ${report.periodDays} дн.'
                      : '${report.periodDays} күндө иш жүзүндөгү сарптоо',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.call_rounded, size: 16),
                      label: Text(
                        '${report.totalCallMinutes.toStringAsFixed(1)} ${isRu ? "мин" : "мүн"}',
                      ),
                    ),
                    Chip(
                      avatar: const Icon(Icons.wifi_rounded, size: 16),
                      label: Text('${gbUsed.toStringAsFixed(2)} ГБ'),
                    ),
                    Chip(
                      avatar: const Icon(Icons.sms_rounded, size: 16),
                      label: Text('${report.totalSmsCount} SMS'),
                    ),
                    Chip(
                      avatar: const Icon(Icons.payments_rounded, size: 16),
                      label: Text(
                        '${formatSom(report.totalSpendSom)} сом',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (best != null) ...[
          const SizedBox(height: 14),
          Card(
            color: AppTheme.electricGreen.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        color: AppTheme.electricGreen,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isRu
                              ? 'Лучший тариф: ${best.plan.operatorName} · ${best.plan.name}'
                              : 'Эң пайдалуу тариф: ${best.plan.operatorName} · ${best.plan.name}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isRu
                        ? 'Расчётная стоимость: ${formatSom(best.estimatedMonthlyCostSom)} сом/мес · '
                            'Годовая экономия: ${formatSom(best.yearlySavingsSom)} сом/год'
                        : 'Айлык баасы: ${formatSom(best.estimatedMonthlyCostSom)} сом/ай · '
                            'Жылдык үнөм: ${formatSom(best.yearlySavingsSom)} сом/жыл',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.electricGreen,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final op in const ['ALL', 'O!', 'Beeline', 'Mega'])
              ChoiceChip(
                selected: _selectedOperator == op,
                label: Text(op == 'ALL' ? (isRu ? 'Все операторы' : 'Баары') : op),
                onSelected: (_) => setState(() => _selectedOperator = op),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...filtered.map((rec) => _buildTariffCard(context, rec, isRu)),
      ],
    );
  }

  Widget _buildTariffCard(
    BuildContext context,
    TariffRecommendation rec,
    bool isRu,
  ) {
    final theme = Theme.of(context);
    final hasSavings = rec.yearlySavingsSom > Decimal.zero;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Chip(label: Text(rec.plan.operatorName)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rec.plan.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${formatSom(rec.estimatedMonthlyCostSom)} сом/мес',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Text(
                    '${isRu ? "Абонплата" : "Айлык акы"}: ${formatSom(rec.plan.monthlyFeeSom)} сом',
                  ),
                  Text('· ${rec.plan.includedMinutes} ${isRu ? "мин" : "мүн"}'),
                  Text('· ${rec.plan.includedGb.toStringAsFixed(0)} ГБ'),
                  Text('· ${rec.plan.includedSms} SMS'),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (hasSavings)
                    Chip(
                      backgroundColor: AppTheme.electricGreen.withValues(alpha: 0.14),
                      label: Text(
                        '${isRu ? "Экономия" : "Үнөм"}: ${formatSom(rec.yearlySavingsSom)} сом/${isRu ? "год" : "жыл"}',
                        style: const TextStyle(
                          color: AppTheme.electricGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Chip(
                    label: Text(
                      rec.fitsMinutes && rec.fitsData
                          ? (isRu ? 'Пакет покрывает трафик' : 'Пакет жетиштүү')
                          : (isRu ? 'С учётом доплаты сверх пакета' : 'Кошумча төлөм менен'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
