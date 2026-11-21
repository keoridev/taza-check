import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/decimal_utils.dart';
import '../../domain/entities/tariff_plan.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/operator_logo.dart';

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
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      OperatorLogo(
                        operatorName: best.plan.operatorName,
                        size: 44,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isRu
                                  ? 'Рекомендуем · Лучший тариф · ${best.plan.operatorName}'
                                  : 'Сунуш · Эң пайдалуу тариф · ${best.plan.operatorName}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              best.plan.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${formatSom(best.estimatedMonthlyCostSom)} сом/${isRu ? "мес" : "ай"}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+${formatSom(best.yearlySavingsSom)} сом/${isRu ? "год" : "жыл"}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.electricGreen,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildBeforeAfterBar(
                    context,
                    currentSom: report.totalSpendSom,
                    optimalSom: best.estimatedMonthlyCostSom,
                    isRu: isRu,
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final op in const ['ALL', 'O!', 'Beeline', 'Mega'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: _selectedOperator == op,
                    avatar: op == 'ALL'
                        ? null
                        : OperatorLogo(operatorName: op, size: 18),
                    label: Text(op == 'ALL' ? (isRu ? 'Все' : 'Баары') : op),
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedOperator = op);
                    },
                  ),
                ),
            ],
          ),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  OperatorLogo(
                    operatorName: rec.plan.operatorName,
                    size: 36,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rec.plan.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${formatSom(rec.estimatedMonthlyCostSom)} сом/${isRu ? "мес" : "ай"}',
                    style: theme.textTheme.titleSmall?.copyWith(
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () async {
                    final ussd = _ussdForPlan(rec.plan);
                    await Clipboard.setData(ClipboardData(text: ussd));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isRu
                                ? 'USSD-код $ussd для «${rec.plan.name}» скопирован!'
                                : '«${rec.plan.name}» үчүн $ussd коду көчүрүлдү!',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.dialpad_rounded, size: 16),
                  label: Text(
                    isRu
                        ? 'Подключить · ${_ussdForPlan(rec.plan)}'
                        : 'Кошуу · ${_ussdForPlan(rec.plan)}',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ussdForPlan(TariffPlan plan) {
    return switch (plan.operatorName) {
      'O!' => '*155*${plan.monthlyFeeSom.toBigInt()}#',
      'Beeline' => '*505*${plan.monthlyFeeSom.toBigInt()}#',
      _ => '*778*${plan.monthlyFeeSom.toBigInt()}#',
    };
  }

  Widget _buildBeforeAfterBar(
    BuildContext context, {
    required Decimal currentSom,
    required Decimal optimalSom,
    required bool isRu,
  }) {
    final cur = currentSom.toDouble();
    final opt = optimalSom.toDouble();
    final ratio = cur > 0 ? (opt / cur).clamp(0.08, 1.0) : 1.0;
    final discountPct = cur > opt && cur > 0
        ? (((cur - opt) / cur) * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isRu
                      ? 'Сейчас: ${formatSom(currentSom)} сом/мес'
                      : 'Азыр: ${formatSom(currentSom)} сом/ай',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppTheme.coralRed,
                  ),
                ),
              ),
              if (discountPct > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '-$discountPct%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: AppTheme.electricGreen,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 8,
              color: AppTheme.coralRed.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isRu
                ? 'С оптимальным тарифом: ${formatSom(optimalSom)} сом/мес'
                : 'Оптималдуу тариф менен: ${formatSom(optimalSom)} сом/ай',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: AppTheme.electricGreen,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.electricGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
