import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/decimal_utils.dart';
import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/anomaly.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';

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
    final isRu = controller.language == AppLanguage.ru;
    final overcharge = result.totalOverchargeSom;
    final hasOvercharge = overcharge > Decimal.zero;
    final memberName = controller.activeMember?.name ?? '';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          color: hasOvercharge
              ? AppTheme.coralRed.withValues(alpha: 0.14)
              : AppTheme.electricGreen.withValues(alpha: 0.14),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      hasOvercharge
                          ? Icons.warning_amber_rounded
                          : Icons.verified_user_rounded,
                      size: 36,
                      color: hasOvercharge
                          ? AppTheme.coralRed
                          : AppTheme.electricGreen,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isRu
                            ? 'Проверка номера ($memberName)'
                            : 'Номерди текшерүү ($memberName)',
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  isRu
                      ? 'Потрачено всего: ${formatSom(result.report.totalSpendSom)} сом'
                      : 'Жалпы сарпталды: ${formatSom(result.report.totalSpendSom)} сом',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  hasOvercharge
                      ? (isRu
                          ? 'Лишние списания: ${formatSom(overcharge)} сом! Найдено проблем: ${result.anomalies.length}.'
                          : 'Ашыкча алынган акча: ${formatSom(overcharge)} сом! Көйгөйлөр: ${result.anomalies.length}.')
                      : (isRu
                          ? 'Всё спокойно: лишних подписок и списаний нет.'
                          : 'Баары жайында: ашыкча жазылуулар жок.'),
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
                        isRu ? 'Сделать заявление на возврат' : 'Кайтаруу арызын жасоо',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.loadCustomCsvForActiveMember,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: Text(
                        isRu ? 'Загрузить другой файл' : 'Башка файл жүктөө',
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
          isRu ? 'Что нужно отключить или проверить:' : 'Эмнени өчүрүү же текшерүү керек:',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (result.anomalies.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                isRu
                    ? 'Подозрительных операций не обнаружено.'
                    : 'Шектүү операциялар табылган жок.',
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
                        '${AppStrings.anomalyTitle(anomaly.type, controller.language)} — ${formatSom(anomaly.costSom)} сом',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isRu ? anomaly.explanationRu : anomaly.explanationKy,
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
                                    isRu
                                        ? 'Скопировано: $copyText'
                                        : 'Көчүрүлдү: $copyText',
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
