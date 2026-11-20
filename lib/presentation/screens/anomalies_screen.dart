import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/decimal_utils.dart';
import '../../domain/entities/anomaly.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';

/// Anomaly inspector (`Аномалии`): filterable by type with explanations,
/// refund badges, and 1-tap copyable USSD/SMS unsubscribe hints.
class AnomaliesScreen extends StatefulWidget {
  const AnomaliesScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  State<AnomaliesScreen> createState() => _AnomaliesScreenState();
}

class _AnomaliesScreenState extends State<AnomaliesScreen> {
  AnomalyType? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final result = controller.activeResult;
    final isRu = controller.language == AppLanguage.ru;

    if (result == null) {
      return Center(
        child: Text(isRu ? 'Нет загруженных данных' : 'Маалымат жүктөлгөн эмес'),
      );
    }

    final filtered = _selectedFilter == null
        ? result.anomalies
        : result.anomalies.where((a) => a.type == _selectedFilter).toList();

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
                      ? 'Фильтр по типу аномалии (${filtered.length}/${result.anomalies.length})'
                      : 'Аномалия түрү боюнча чыпка (${filtered.length}/${result.anomalies.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      selected: _selectedFilter == null,
                      label: Text('${isRu ? "Все" : "Баары"} (${result.anomalies.length})'),
                      onSelected: (_) => setState(() => _selectedFilter = null),
                    ),
                    ...AnomalyType.values.map((type) {
                      final count =
                          result.anomalies.where((a) => a.type == type).length;
                      return FilterChip(
                        selected: _selectedFilter == type,
                        label: Text(
                          '${AppStrings.anomalyTitle(type, controller.language)} ($count)',
                        ),
                        onSelected: (_) => setState(() {
                          _selectedFilter =
                              _selectedFilter == type ? null : type;
                        }),
                      );
                    }),
                  ],
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
                  isRu
                      ? 'В этой категории аномалий не найдено.'
                      : 'Бул категорияда аномалиялар табылган жок.',
                ),
              ),
            ),
          )
        else
          ...filtered.map((anomaly) => _buildAnomalyCard(context, anomaly, isRu)),
      ],
    );
  }

  Widget _buildAnomalyCard(
    BuildContext context,
    Anomaly anomaly,
    bool isRu,
  ) {
    final controller = widget.controller;
    final theme = Theme.of(context);
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          AppStrings.anomalyTitle(
                            anomaly.type,
                            controller.language,
                          ),
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        anomaly.datetime,
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isSpike
                          ? theme.colorScheme.secondaryContainer
                          : AppTheme.electricGreen.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isSpike
                          ? '${isRu ? "Трата за день" : "Күндүк чыгым"}: ${formatSom(anomaly.costSom)} сом'
                          : '${isRu ? "Возврат" : "Кайтаруу"}: ${formatSom(anomaly.overchargeSom)} сом',
                      style: TextStyle(
                        color: isSpike
                            ? theme.colorScheme.onSecondaryContainer
                            : AppTheme.electricGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (anomaly.number != null && anomaly.number!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${isRu ? "Номер" : "Номер"}: ${anomaly.number}'
                    '${anomaly.rowNumber != null ? " · ${isRu ? "строка" : "сап"} #${anomaly.rowNumber}" : ""}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Text(
                isRu ? anomaly.explanationRu : anomaly.explanationKy,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (anomaly.ussdHint != null)
                    ActionChip(
                      avatar: const Icon(Icons.copy_rounded, size: 16),
                      label: Text(anomaly.ussdHint!),
                      onPressed: () async {
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
                                isRu
                                    ? 'Скопировано в буфер: $copyPayload'
                                    : 'Көчүрүлдү: $copyPayload',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  if (!isSpike && anomaly.overchargeSom > Decimal.zero)
                    FilterChip(
                      selected: isSelectedForClaim,
                      label: Text(
                        isRu ? 'Включить в заявление' : 'Арызга кошуу',
                      ),
                      onSelected: (_) =>
                          controller.toggleClaimAnomaly(anomaly.id),
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
