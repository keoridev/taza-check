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
    final lang = controller.language;
    final tr = AppStrings.tr;
    final cur = AppStrings.currency(lang);

    if (result == null) {
      return Center(
        child: Text(
          tr(
            lang,
            ru: 'Нет данных для подбора',
            ky: 'Маалымат жок',
            en: 'No usage data available',
          ),
        ),
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
                  tr(
                    lang,
                    ru: 'Фактическое потребление за ${report.periodDays} дн.',
                    ky: '${report.periodDays} күндө иш жүзүндөгү сарптоо',
                    en: 'Actual usage over ${report.periodDays} days',
                  ),
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
                        '${report.totalCallMinutes.toStringAsFixed(1)} ${tr(lang, ru: "мин", ky: "мүн", en: "min")}',
                      ),
                    ),
                    Chip(
                      avatar: const Icon(Icons.wifi_rounded, size: 16),
                      label: Text(
                        '${gbUsed.toStringAsFixed(2)} ${tr(lang, ru: "ГБ", ky: "ГБ", en: "GB")}',
                      ),
                    ),
                    Chip(
                      avatar: const Icon(Icons.sms_rounded, size: 16),
                      label: Text('${report.totalSmsCount} SMS'),
                    ),
                    Chip(
                      avatar: const Icon(Icons.payments_rounded, size: 16),
                      label: Text('${formatSom(report.totalSpendSom)} $cur'),
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
                              tr(
                                lang,
                                ru: 'Рекомендуем · Лучший тариф · ${best.plan.operatorName}',
                                ky: 'Сунуш · Эң пайдалуу тариф · ${best.plan.operatorName}',
                                en: 'Recommended · Best plan · ${best.plan.operatorName}',
                              ),
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
                          '${formatSom(best.estimatedMonthlyCostSom)} $cur/${tr(lang, ru: "мес", ky: "ай", en: "mo")}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+${formatSom(best.yearlySavingsSom)} $cur/${tr(lang, ru: "год", ky: "жыл", en: "yr")}',
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
                    lang: lang,
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
                    label: Text(
                      op == 'ALL'
                          ? tr(lang, ru: 'Все', ky: 'Баары', en: 'All')
                          : op,
                    ),
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
        ...filtered.map((rec) => _buildTariffCard(context, rec, lang)),
      ],
    );
  }

  Widget _buildTariffCard(
    BuildContext context,
    TariffRecommendation rec,
    AppLanguage lang,
  ) {
    final theme = Theme.of(context);
    final tr = AppStrings.tr;
    final cur = AppStrings.currency(lang);
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
                    '${formatSom(rec.estimatedMonthlyCostSom)} $cur/${tr(lang, ru: "мес", ky: "ай", en: "mo")}',
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
                    '${tr(lang, ru: "Абонплата", ky: "Айлык акы", en: "Monthly fee")}: ${formatSom(rec.plan.monthlyFeeSom)} $cur',
                  ),
                  Text(
                    '· ${rec.plan.includedMinutes} ${tr(lang, ru: "мин", ky: "мүн", en: "min")}',
                  ),
                  Text(
                    '· ${rec.plan.includedGb.toStringAsFixed(0)} ${tr(lang, ru: "ГБ", ky: "ГБ", en: "GB")}',
                  ),
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
                        '${tr(lang, ru: "Экономия", ky: "Үнөм", en: "Savings")}: ${formatSom(rec.yearlySavingsSom)} $cur/${tr(lang, ru: "год", ky: "жыл", en: "yr")}',
                        style: const TextStyle(
                          color: AppTheme.electricGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Chip(
                    label: Text(
                      rec.fitsMinutes && rec.fitsData
                          ? tr(
                              lang,
                              ru: 'Пакет покрывает трафик',
                              ky: 'Пакет жетиштүү',
                              en: 'Plan covers your usage',
                            )
                          : tr(
                              lang,
                              ru: 'С учётом доплаты сверх пакета',
                              ky: 'Кошумча төлөм менен',
                              en: 'Includes overage estimate',
                            ),
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
                            tr(
                              lang,
                              ru: 'USSD-код $ussd для «${rec.plan.name}» скопирован!',
                              ky: '«${rec.plan.name}» үчүн $ussd коду көчүрүлдү!',
                              en: 'USSD code $ussd for "${rec.plan.name}" copied!',
                            ),
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.dialpad_rounded, size: 16),
                  label: Text(
                    '${tr(lang, ru: "Подключить", ky: "Кошуу", en: "Activate")} · ${_ussdForPlan(rec.plan)}',
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
    required AppLanguage lang,
  }) {
    final tr = AppStrings.tr;
    final curUnit = AppStrings.currency(lang);
    final moUnit = tr(lang, ru: 'мес', ky: 'ай', en: 'mo');
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
                  '${tr(lang, ru: "Сейчас", ky: "Азыр", en: "Current")}: ${formatSom(currentSom)} $curUnit/$moUnit',
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
            '${tr(lang, ru: "С оптимальным тарифом", ky: "Оптималдуу тариф менен", en: "With optimal plan")}: ${formatSom(optimalSom)} $curUnit/$moUnit',
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
