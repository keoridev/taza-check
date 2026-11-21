import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/decimal_utils.dart';
import '../../domain/entities/anomaly.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_som_text.dart';

/// 1-click legal claim builder and export screen (`Заявление и экспорт`).
class ClaimExportScreen extends StatefulWidget {
  const ClaimExportScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  State<ClaimExportScreen> createState() => _ClaimExportScreenState();
}

class _ClaimExportScreenState extends State<ClaimExportScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _operatorCtrl;
  late final TextEditingController _cityCtrl;
  String _syncedMemberId = '';

  @override
  void initState() {
    super.initState();
    final info = widget.controller.subscriberInfo;
    _nameCtrl = TextEditingController(text: info.fullName);
    _phoneCtrl = TextEditingController(text: info.phone);
    _operatorCtrl = TextEditingController(text: info.operatorName);
    _cityCtrl = TextEditingController(text: info.city);
    _syncedMemberId = widget.controller.activeMemberId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _operatorCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  void _syncFromControllerIfNeeded() {
    final activeId = widget.controller.activeMemberId;
    if (activeId != _syncedMemberId) {
      _syncedMemberId = activeId;
      final info = widget.controller.subscriberInfo;
      _nameCtrl.text = info.fullName;
      _phoneCtrl.text = info.phone;
      _operatorCtrl.text = info.operatorName;
      _cityCtrl.text = info.city;
    }
  }

  @override
  Widget build(BuildContext context) {
    _syncFromControllerIfNeeded();
    final controller = widget.controller;
    final result = controller.activeResult;
    final lang = controller.language;
    final tr = AppStrings.tr;
    final cur = AppStrings.currency(lang);
    final theme = Theme.of(context);

    if (result == null) {
      return Center(
        child: Text(
          tr(
            lang,
            ru: 'Нет данных для заявления',
            ky: 'Маалымат жок',
            en: 'No billing data for a claim',
          ),
        ),
      );
    }

    final claimable = result.anomalies
        .where((a) => a.type != AnomalyType.daySpike && a.overchargeSom > Decimal.zero)
        .toList();
    final claimText = controller.generatedClaimText;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AnimatedSomText(
                      amount: controller.selectedClaimRefundTotal,
                      prefix: tr(
                        lang,
                        ru: 'Сумма к возврату: ',
                        ky: 'Кайтаруу суммасы: ',
                        en: 'Refund total: ',
                      ),
                      suffix: ' $cur',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.electricGreen,
                      ),
                    ),
                    SegmentedButton<AppLanguage>(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppTheme.beelineYellow;
                          }
                          return null;
                        }),
                        foregroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppTheme.obsidianBlack;
                          }
                          return null;
                        }),
                        textStyle: const WidgetStatePropertyAll(
                          TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      segments: const [
                        ButtonSegment(value: AppLanguage.ru, label: Text('RU')),
                        ButtonSegment(value: AppLanguage.ky, label: Text('KY')),
                        ButtonSegment(value: AppLanguage.en, label: Text('EN')),
                      ],
                      selected: <AppLanguage>{lang},
                      onSelectionChanged: (s) {
                        HapticFeedback.selectionClick();
                        controller.setLanguage(s.first);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 560;
                    final nameField = TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: tr(
                          lang,
                          ru: 'ФИО абонента',
                          ky: 'Абоненттин аты-жөнү',
                          en: 'Full name',
                        ),
                      ),
                      onChanged: (v) =>
                          controller.updateSubscriberInfo(fullName: v),
                    );
                    final phoneField = TextField(
                      controller: _phoneCtrl,
                      decoration: InputDecoration(
                        labelText: tr(
                          lang,
                          ru: 'Номер телефона',
                          ky: 'Телефон номери',
                          en: 'Phone number',
                        ),
                      ),
                      onChanged: (v) =>
                          controller.updateSubscriberInfo(phone: v),
                    );
                    final operatorField = TextField(
                      controller: _operatorCtrl,
                      decoration: InputDecoration(
                        labelText: tr(
                          lang,
                          ru: 'Оператор',
                          ky: 'Оператор',
                          en: 'Operator',
                        ),
                      ),
                      onChanged: (v) =>
                          controller.updateSubscriberInfo(operatorName: v),
                    );
                    final cityField = TextField(
                      controller: _cityCtrl,
                      decoration: InputDecoration(
                        labelText: tr(
                          lang,
                          ru: 'Город',
                          ky: 'Шаар',
                          en: 'City',
                        ),
                      ),
                      onChanged: (v) =>
                          controller.updateSubscriberInfo(city: v),
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          nameField,
                          const SizedBox(height: 12),
                          phoneField,
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: operatorField),
                              const SizedBox(width: 12),
                              Expanded(child: cityField),
                            ],
                          ),
                        ],
                      );
                    }

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(width: 260, child: nameField),
                        SizedBox(width: 200, child: phoneField),
                        SizedBox(width: 140, child: operatorField),
                        SizedBox(width: 160, child: cityField),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      tr(
                        lang,
                        ru: 'Оспариваемые списания (${controller.selectedClaimAnomalies.length}/${claimable.length})',
                        ky: 'Талаштуу төлөмдөр (${controller.selectedClaimAnomalies.length}/${claimable.length})',
                        en: 'Disputed charges (${controller.selectedClaimAnomalies.length}/${claimable.length})',
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => controller.selectAllClaimAnomalies(true),
                          child: Text(
                            tr(lang, ru: 'Выбрать все', ky: 'Баарын тандоо', en: 'Select all'),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              controller.selectAllClaimAnomalies(false),
                          child: Text(
                            tr(lang, ru: 'Снять все', ky: 'Тазалоо', en: 'Clear'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (claimable.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      tr(
                        lang,
                        ru: 'Нет списаний для возврата.',
                        ky: 'Кайтарууга төлөмдөр жок.',
                        en: 'No refundable charges found.',
                      ),
                    ),
                  )
                else
                  ...claimable.map((a) {
                    final checked =
                        controller.selectedClaimAnomalyIds.contains(a.id);
                    return CheckboxListTile(
                      value: checked,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (_) => controller.toggleClaimAnomaly(a.id),
                      title: Text(
                        '${AppStrings.anomalyTitle(a.type, lang)} · ${formatSom(a.overchargeSom)} $cur',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('${a.datetime} · ${a.number ?? "-"}'),
                    );
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      tr(
                        lang,
                        ru: 'Предпросмотр заявления (claim.txt)',
                        ky: 'Арызды алдын ала көрүү (claim.txt)',
                        en: 'Claim preview (claim.txt)',
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: claimText),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    tr(
                                      lang,
                                      ru: 'Текст заявления скопирован',
                                      ky: 'Арыздын тексти көчүрүлдү',
                                      en: 'Claim text copied',
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: Text(
                            tr(lang, ru: 'Копировать', ky: 'Көчүрүү', en: 'Copy'),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _handleExport(context, 'claim.txt', () {
                            return controller.exportClaimTxt();
                          }),
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('claim.txt'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _handleExport(context, 'anomalies.json', () {
                            return controller.exportAnomaliesJson();
                          }),
                          icon: const Icon(Icons.data_object_rounded, size: 18),
                          label: const Text('anomalies.json'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _handleExport(context, 'dropped_rows.csv', () {
                            return controller.exportDroppedRowsCsv();
                          }),
                          icon: const Icon(Icons.table_rows_rounded, size: 18),
                          label: const Text('dropped_rows.csv'),
                        ),
                        IconButton(
                          tooltip: tr(
                            lang,
                            ru: 'Поделиться',
                            ky: 'Бөлүшүү',
                            en: 'Share',
                          ),
                          onPressed: () => _handleExport(
                            context,
                            'claim.txt',
                            () => controller.exportClaimTxt(shareViaSheet: true),
                          ),
                          icon: const Icon(Icons.share_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: SelectableText(
                    claimText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleExport(
    BuildContext context,
    String fileName,
    Future<String?> Function() action,
  ) async {
    final lang = widget.controller.language;
    try {
      final path = await action();
      if (!context.mounted) return;
      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.tr(
                lang,
                ru: 'Экспортировано: $fileName',
                ky: 'Экспорттолду: $fileName',
                en: 'Exported: $fileName',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$fileName: $e')),
      );
    }
  }
}
