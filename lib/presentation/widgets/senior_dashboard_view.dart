import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/decimal_utils.dart';
import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/anomaly.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'bee_mascot.dart';
import 'guide_stories_modal.dart';

/// High-contrast, large-font simplified dashboard for parents & grandparents.
class SeniorDashboardView extends StatelessWidget {
  const SeniorDashboardView({
    super.key,
    required this.controller,
    required this.result,
  });

  final AppController controller;
  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = controller.language;
    final tr = AppStrings.tr;
    final cur = AppStrings.currency(lang);
    final overcharge = result.totalOverchargeSom;
    final hasOvercharge = overcharge > Decimal.zero;
    final memberName = controller.activeMember?.name ?? '';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          color: AppTheme.beelineYellow.withValues(alpha: 0.14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: AppTheme.beelineYellow, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BeeMascot(
              state: MascotState.seniorHelper,
              size: 100,
              language: lang,
              message: hasOvercharge
                  ? tr(
                      lang,
                      ru: 'Не переживайте! Я проверил ваш баланс и нашёл, как отключить платные рассылки одной кнопкой.',
                      ky: 'Кабатыр болбоңуз! Балансыңызды текшердим, ашыкча төлөмдөрдү бир баскыч менен өчүрөбүз.',
                      en: 'Don\'t worry! I checked your balance and found how to cancel paid subscriptions with one tap.',
                    )
                  : tr(
                      lang,
                      ru: 'Всё в порядке! Я проверил все списания — лишних подписок и скрытых платежей нет.',
                      ky: 'Баары жайында! Бардык списаниелер таза, жашыруун жазылуулар жок.',
                      en: 'Everything looks great! I checked all charges — no hidden subscriptions or extra fees.',
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      hasOvercharge
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 36,
                      color: hasOvercharge
                          ? AppTheme.coralRed
                          : AppTheme.electricGreen,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tr(
                          lang,
                          ru: 'Проверка номера ($memberName)',
                          ky: 'Номерди текшерүү ($memberName)',
                          en: 'Number check ($memberName)',
                        ),
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  tr(
                    lang,
                    ru: 'Потрачено всего: ${formatSom(result.report.totalSpendSom)} сом',
                    ky: 'Жалпы сарпталды: ${formatSom(result.report.totalSpendSom)} сом',
                    en: 'Total spent: ${formatSom(result.report.totalSpendSom)} $cur',
                  ),
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  hasOvercharge
                      ? tr(
                          lang,
                          ru: 'Лишние списания: ${formatSom(overcharge)} сом! Найдено проблем: ${result.anomalies.length}.',
                          ky: 'Ашыкча алынган акча: ${formatSom(overcharge)} сом! Көйгөйлөр: ${result.anomalies.length}.',
                          en: 'Extra charges: ${formatSom(overcharge)} $cur! Issues found: ${result.anomalies.length}.',
                        )
                      : tr(
                          lang,
                          ru: 'Всё спокойно: лишних подписок и списаний нет.',
                          ky: 'Баары жайында: ашыкча жазылуулар жок.',
                          en: 'All clear: no unwanted subscriptions or extra charges.',
                        ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: hasOvercharge
                        ? AppTheme.coralRed
                        : AppTheme.electricGreen,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: () => controller.setTabIndex(4),
                      icon: const Icon(Icons.description_rounded),
                      label: Text(
                        tr(
                          lang,
                          ru: 'Сделать заявление на возврат',
                          ky: 'Кайтаруу арызын жасоо',
                          en: 'Create refund claim',
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.loadCustomCsvForActiveMember,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: Text(
                        tr(
                          lang,
                          ru: 'Загрузить другой файл',
                          ky: 'Башка файл жүктөө',
                          en: 'Load another file',
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => showGuideStories(
                        context,
                        language: lang,
                        onEnableSeniorMode: () => controller.toggleSeniorMode(true),
                      ),
                      icon: const Icon(Icons.play_circle_outline_rounded),
                      label: Text(
                        tr(
                          lang,
                          ru: 'Как пользоваться (обучалка)',
                          ky: 'Кантип колдонуу керек',
                          en: 'How it works (guide)',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          tr(
            lang,
            ru: 'Что нужно отключить или проверить:',
            ky: 'Эмнени өчүрүү же текшерүү керек:',
            en: 'What to cancel or review:',
          ),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (result.anomalies.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                tr(
                  lang,
                  ru: 'Подозрительных операций не обнаружено.',
                  ky: 'Шектүү операциялар табылган жок.',
                  en: 'No suspicious transactions found.',
                ),
                style: theme.textTheme.bodyLarge,
              ),
            ),
          )
        else
          ...result.anomalies.map((anomaly) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppStrings.anomalyTitle(anomaly.type, lang)} — ${formatSom(anomaly.costSom)} $cur',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        anomaly.explanation(lang),
                        style: theme.textTheme.bodyLarge,
                      ),
                      if (anomaly.ussdHint != null) ...[
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: () async {
                            final copyText = anomaly.type == AnomalyType.newSubscription &&
                                    anomaly.number != null
                                ? 'СТОП'
                                : anomaly.ussdHint!;
                            await Clipboard.setData(ClipboardData(text: copyText));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    tr(
                                      lang,
                                      ru: 'Скопировано: $copyText',
                                      ky: 'Көчүрүлдү: $copyText',
                                      en: 'Copied: $copyText',
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy_rounded),
                          label: Text(anomaly.ussdHint!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
