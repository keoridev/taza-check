import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/decimal_utils.dart';
import '../../domain/entities/anomaly.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/bee_mascot.dart';

/// Anomaly inspector (`Аномалии`): filterable by type with explanations,
/// refund badges, and 1-tap copyable USSD/SMS unsubscribe hints.
class AnomaliesScreen extends StatefulWidget {
  const AnomaliesScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  /// Opens the live Beeline Guard SMS Intercept demo modal from any screen.
  static Future<void> showSmsInterceptSheet(
    BuildContext context, {
    required AppLanguage language,
  }) =>
      _showSmsInterceptSheetImpl(context, language);

  @override
  State<AnomaliesScreen> createState() => _AnomaliesScreenState();
}

class _AnomaliesScreenState extends State<AnomaliesScreen> {
  AnomalyType? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final result = controller.activeResult;
    final lang = controller.language;
    final tr = AppStrings.tr;

    if (result == null) {
      return Center(
        child: Text(
          tr(
            lang,
            ru: 'Нет загруженных данных',
            ky: 'Маалымат жүктөлгөн эмес',
            en: 'No billing data loaded',
          ),
        ),
      );
    }

    final filtered = _selectedFilter == null
        ? result.anomalies
        : result.anomalies.where((a) => a.type == _selectedFilter).toList();

    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final allSelected = _selectedFilter == null;
    final filterChips = <Widget>[
      FilterChip(
        selected: allSelected,
        selectedColor: AppTheme.beelineYellow,
        checkmarkColor: AppTheme.obsidianBlack,
        labelStyle: TextStyle(
          color: allSelected ? AppTheme.obsidianBlack : null,
          fontWeight: FontWeight.w700,
        ),
        label: Text(
          '${tr(lang, ru: "Все", ky: "Баары", en: "All")} (${result.anomalies.length})',
          style: TextStyle(
            color: allSelected ? AppTheme.obsidianBlack : null,
            fontWeight: FontWeight.w700,
          ),
        ),
        onSelected: (_) {
          HapticFeedback.selectionClick();
          setState(() => _selectedFilter = null);
        },
      ),
      ...AnomalyType.values.map((type) {
        final count = result.anomalies.where((a) => a.type == type).length;
        final isSelected = _selectedFilter == type;
        return FilterChip(
          selected: isSelected,
          selectedColor: AppTheme.beelineYellow,
          checkmarkColor: AppTheme.obsidianBlack,
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.obsidianBlack : null,
            fontWeight: FontWeight.w700,
          ),
          label: Text(
            '${AppStrings.anomalyTitle(type, lang)} ($count)',
            style: TextStyle(
              color: isSelected ? AppTheme.obsidianBlack : null,
              fontWeight: FontWeight.w700,
            ),
          ),
          onSelected: (_) {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedFilter = _selectedFilter == type ? null : type;
            });
          },
        );
      }),
    ];

    return ListView(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      children: [
        Card(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr(
                          lang,
                          ru: 'Фильтр по типу (${filtered.length}/${result.anomalies.length})',
                          ky: 'Аномалия чыпкасы (${filtered.length}/${result.anomalies.length})',
                          en: 'Filter by type (${filtered.length}/${result.anomalies.length})',
                        ),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.carbonElevated,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () => AnomaliesScreen.showSmsInterceptSheet(
                        context,
                        language: lang,
                      ),
                      icon: const Icon(
                        Icons.sms_failed_rounded,
                        size: 15,
                        color: AppTheme.coralRed,
                      ),
                      label: Text(
                        tr(
                          lang,
                          ru: 'Тест перехвата SMS',
                          ky: 'SMS кармоо тести',
                          en: 'SMS Intercept',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (isMobile)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: filterChips
                          .map((c) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: c,
                              ))
                          .toList(),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: filterChips,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  tr(
                    lang,
                    ru: 'В этой категории аномалий не найдено.',
                    ky: 'Бул категорияда аномалиялар табылган жок.',
                    en: 'No anomalies found in this category.',
                  ),
                ),
              ),
            ),
          )
        else
          ...filtered.map((anomaly) => _buildAnomalyCard(context, anomaly, lang)),
      ],
    );
  }

  Widget _buildAnomalyCard(
    BuildContext context,
    Anomaly anomaly,
    AppLanguage lang,
  ) {
    final controller = widget.controller;
    final theme = Theme.of(context);
    final tr = AppStrings.tr;
    final cur = AppStrings.currency(lang);
    final isSpike = anomaly.type == AnomalyType.daySpike;
    final accent = isSpike ? AppTheme.warmAmber : AppTheme.coralRed;
    final isSelectedForClaim =
        controller.selectedClaimAnomalyIds.contains(anomaly.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          AppStrings.anomalyTitle(anomaly.type, lang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    anomaly.datetime,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    isSpike
                        ? '-${formatSom(anomaly.costSom)} $cur'
                        : '${tr(lang, ru: "К возврату", ky: "Кайтаруу", en: "Refund")}: ${formatSom(anomaly.overchargeSom)} $cur',
                    style: TextStyle(
                      color: isSpike ? AppTheme.coralRed : AppTheme.electricGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (anomaly.number != null && anomaly.number!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${tr(lang, ru: "Номер", ky: "Номер", en: "Number")}: ${anomaly.number}'
                    '${anomaly.rowNumber != null ? " · ${tr(lang, ru: "строка", ky: "сап", en: "row")} #${anomaly.rowNumber}" : ""}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              BeeMascot(
                state: anomaly.type == AnomalyType.duplicateCharge
                    ? MascotState.detective
                    : MascotState.alert,
                compact: true,
                size: 58,
                language: lang,
                message: anomaly.explanation(lang),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (anomaly.ussdHint != null)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final copyPayload =
                            anomaly.type == AnomalyType.newSubscription &&
                                    anomaly.number != null
                                ? 'СТОП'
                                : anomaly.ussdHint!;
                        await Clipboard.setData(ClipboardData(text: copyPayload));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                tr(
                                  lang,
                                  ru: 'Скопировано в буфер: $copyPayload',
                                  ky: 'Көчүрүлдү: $copyPayload',
                                  en: 'Copied to clipboard: $copyPayload',
                                ),
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.copy_rounded, size: 15),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                anomaly.ussdHint!,
                                softWrap: true,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!isSpike && anomaly.overchargeSom > Decimal.zero)
                    FilterChip(
                      selected: isSelectedForClaim,
                      selectedColor: AppTheme.beelineYellow,
                      checkmarkColor: AppTheme.obsidianBlack,
                      labelStyle: TextStyle(
                        color: isSelectedForClaim ? AppTheme.obsidianBlack : null,
                        fontWeight: FontWeight.w700,
                      ),
                      label: Text(
                        tr(
                          lang,
                          ru: 'Включить в заявление',
                          ky: 'Арызга кошуу',
                          en: 'Include in claim',
                        ),
                        style: TextStyle(
                          color: isSelectedForClaim
                              ? AppTheme.obsidianBlack
                              : null,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        controller.toggleClaimAnomaly(anomaly.id);
                      },
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

Future<void> _showSmsInterceptSheetImpl(
  BuildContext context,
  AppLanguage language,
) async {
  HapticFeedback.mediumImpact();
  var neutralized = false;
  final tr = AppStrings.tr;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.carbonSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                24 + MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(
                        neutralized
                            ? Icons.check_circle_outline_rounded
                            : Icons.bolt_rounded,
                        color: neutralized
                            ? AppTheme.electricGreen
                            : AppTheme.coralRed,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          neutralized
                              ? tr(
                                  language,
                                  ru: 'Угроза заблокирована!',
                                  ky: 'Коркунуч бөгөттөлдү!',
                                  en: 'Threat blocked!',
                                )
                              : tr(
                                  language,
                                  ru: 'Beeline Guard · Перехват SMS',
                                  ky: 'Beeline Guard · SMS кармоо',
                                  en: 'Beeline Guard · SMS Intercept',
                                ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  BeeMascot(
                    state: neutralized ? MascotState.happy : MascotState.alert,
                    size: 72,
                    language: language,
                    message: neutralized
                        ? tr(
                            language,
                            ru: 'Отлично! Команда СТОП отправлена на 7575, вы сэкономили 5 475 сом/год.',
                            ky: 'Азаматсыз! 7575 номерине СТОП жөнөтүлдү, жылына 5 475 сом үнөмдөлдү.',
                            en: 'Great! STOP sent to 7575 — you just saved 5,475 KGS/year.',
                          )
                        : tr(
                            language,
                            ru: 'Осторожно! Прямо сейчас вам пытаются подключить платную подписку на 5 475 сом/год!',
                            ky: 'Абайлаңыз! Азыр сизге жылына 5 475 сомдук акы төлөнүүчү жазылуу кошулууда!',
                            en: 'Watch out! A paid subscription costing 5,475 KGS/year is trying to activate right now!',
                          ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.carbonInput,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(
                            language,
                            ru: 'От 7575: Подписка «Гороскоп VIP» активирована. Списание 15.00 сом/сутки.',
                            ky: '7575тен: «Гороскоп VIP» жазылуусу кошулду. Күнүнө 15.00 сом алынат.',
                            en: 'From 7575: "Horoscope VIP" subscription activated. Charge: 15.00 KGS/day.',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr(
                            language,
                            ru: 'Потенциальная потеря: 5 475 сом/год',
                            ky: 'Жылдык жоготуу: 5 475 сом/жыл',
                            en: 'Potential annual loss: 5,475 KGS/year',
                          ),
                          style: TextStyle(
                            color: neutralized
                                ? AppTheme.electricGreen
                                : AppTheme.coralRed,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!neutralized)
                    FilledButton.icon(
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        setSheetState(() => neutralized = true);
                        await Clipboard.setData(const ClipboardData(text: 'СТОП'));
                      },
                      icon: const Icon(Icons.block_rounded),
                      label: Text(
                        tr(
                          language,
                          ru: 'Заблокировать и отправить СТОП',
                          ky: 'Бөгөттөө жана СТОП жөнөтүү',
                          en: 'Block & send STOP',
                        ),
                      ),
                    )
                  else
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.electricGreen,
                        foregroundColor: AppTheme.obsidianBlack,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: Text(
                        tr(language, ru: 'Готово', ky: 'Даяр', en: 'Done'),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
