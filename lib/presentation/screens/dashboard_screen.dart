import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/engine/llm_service.dart';
import '../../core/utils/decimal_utils.dart';
import '../../domain/entities/analysis_result.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/bee_mascot.dart';
import '../widgets/category_breakdown_chart.dart';
import '../widgets/daily_spend_chart.dart';
import '../widgets/kpi_card.dart';
import '../widgets/senior_dashboard_view.dart';

/// Main overview screen (`Обзор`): Compact Telecom Balance hero card with BeeMascot,
/// tight 2×2 KPI grid, unified analytics card (`По дням` / `Категории` / `Топ-5`),
/// and collapsible AI/Decimal audit summary.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _analyticsTab = 0;
  bool _auditExpanded = false;

  AppController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    final result = controller.activeResult;
    final isRu = controller.language == AppLanguage.ru;

    if (controller.isBusy && result == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: BeeMascot(
            state: MascotState.loader,
            size: 112,
            language: controller.language,
          ),
        ),
      );
    }

    if (result == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.beelineYellow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  size: 48,
                  color: AppTheme.obsidianBlack,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isRu
                    ? 'Загрузите CSV детализацию или встроенное демо'
                    : 'CSV детализацияны же орнотулган демону жүктөңүз',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: controller.loadCustomCsvForActiveMember,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(isRu ? 'Загрузить CSV' : 'CSV жүктөө'),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.loadDemoFamily,
                    icon: const Icon(Icons.groups_rounded),
                    label: Text(
                      isRu
                          ? 'Загрузить встроенное демо (5 абонентов)'
                          : 'Демо жүктөө (5 абонент)',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (controller.seniorMode) {
      return SeniorDashboardView(controller: controller, result: result);
    }

    return RefreshIndicator(
      color: AppTheme.beelineYellow,
      onRefresh: controller.loadDemoFamily,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _buildHeroBalanceCard(context, result, isRu),
          const SizedBox(height: 12),
          _buildKpiGrid(context, result, isRu),
          const SizedBox(height: 12),
          _buildAnalyticsCard(context, result, isRu),
          const SizedBox(height: 12),
          _buildCollapsibleSummaryCard(context, result, isRu),
        ],
      ),
    );
  }

  Widget _buildHeroBalanceCard(
    BuildContext context,
    AnalysisResult result,
    bool isRu,
  ) {
    final member = controller.activeMember;
    final bestTariff = controller.tariffRecommendations.isNotEmpty
        ? controller.tariffRecommendations.first
        : null;
    final mascotInfo = BeeMascot.fromAnalysis(
      result: result,
      language: controller.language,
      bestTariff: bestTariff,
    );
    final hasOvercharge = result.totalOverchargeSom > Decimal.zero;
    final statusPillText = hasOvercharge
        ? (isRu
            ? 'Найдено ${result.anomalies.length} угроз на ${formatSom(result.totalOverchargeSom)} сом →'
            : '${result.anomalies.length} коркунуч (${formatSom(result.totalOverchargeSom)} сом) →')
        : (bestTariff != null && bestTariff.yearlySavingsSom > Decimal.zero
            ? (isRu
                ? 'Всё чисто! Тариф сэкономит ${formatSom(bestTariff.yearlySavingsSom)} сом/год →'
                : 'Баары таза! Тариф ${formatSom(bestTariff.yearlySavingsSom)} сом/жыл үнөмдөйт →')
            : mascotInfo.message);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1D1D22),
              Color(0xFF101014),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.carbonBorder),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -36,
              top: -28,
              child: Transform.rotate(
                angle: -0.45,
                child: Container(
                  width: 110,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.beelineYellow.withValues(alpha: 0.20),
                        AppTheme.beelineYellow.withValues(alpha: 0.03),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.beelineYellow,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    member?.operatorName ?? 'Mobile KG',
                                    style: const TextStyle(
                                      color: AppTheme.obsidianBlack,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                Text(
                                  member != null
                                      ? '${member.name} · ${member.roleLabel}'
                                      : result.sourceName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${member?.phone ?? ""} · ${result.report.periodDays} ${isRu ? "дн." : "күн"}',
                              style: const TextStyle(
                                color: AppTheme.coolGray,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        onPressed: controller.loadCustomCsvForActiveMember,
                        icon: const Icon(Icons.upload_file_rounded, size: 16),
                        label: Text(isRu ? 'Загрузить CSV' : 'CSV'),
                      ),
                      const SizedBox(width: 6),
                      IconButton.outlined(
                        tooltip: isRu ? 'Загрузить демо' : 'Демо жүктөө',
                        style: IconButton.styleFrom(
                          foregroundColor: AppTheme.beelineYellow,
                          side: const BorderSide(color: Color(0xFF3A3A44)),
                        ),
                        onPressed: controller.loadDemoFamily,
                        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => controller.setTabIndex(hasOvercharge ? 1 : 3),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: (hasOvercharge
                                ? AppTheme.coralRed
                                : AppTheme.electricGreen)
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (hasOvercharge
                                  ? AppTheme.coralRed
                                  : AppTheme.beelineYellow)
                              .withValues(alpha: 0.55),
                        ),
                      ),
                      child: Row(
                        children: [
                          BeeMascot(
                            state: mascotInfo.state,
                            size: 44,
                            showBubble: false,
                            language: controller.language,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              statusPillText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiGrid(
    BuildContext context,
    AnalysisResult result,
    bool isRu,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final isCompact = w < 700;
        final crossCount = w >= 1000 ? 4 : 2;
        final cardWidth = (w - (crossCount - 1) * 10) / crossCount;

        final cards = <Widget>[
          KpiCard(
            title: isCompact
                ? (isRu ? 'Всего трат' : 'Жалпы')
                : (isRu ? 'Всего потрачено' : 'Жалпы сарпталды'),
            value: '${formatSom(result.report.totalSpendSom)} сом',
            subtitle:
                '${result.records.length} ${isRu ? "операций" : "операция"}',
            icon: Icons.account_balance_wallet_rounded,
            accentColor: AppTheme.beelineYellow,
            compact: isCompact,
          ),
          KpiCard(
            title: isCompact
                ? (isRu ? 'Переплата' : 'Ашыкча')
                : (isRu ? 'Возможная переплата' : 'Мүмкүн ашыкча төлөм'),
            value: '${formatSom(result.totalOverchargeSom)} сом',
            subtitle:
                '${result.anomalies.length} ${isRu ? "аномалий" : "аномалия"}',
            icon: Icons.gpp_maybe_rounded,
            accentColor: result.totalOverchargeSom > Decimal.zero
                ? AppTheme.coralRed
                : AppTheme.electricGreen,
            compact: isCompact,
            onTap: () => controller.setTabIndex(1),
          ),
          KpiCard(
            title: isCompact
                ? (isRu ? 'Утечка / год' : 'Жылдык')
                : (isRu
                    ? 'Прогноз утечки за год (подписки × 12)'
                    : 'Жылдык жоготуу (жазылуу × 12)'),
            value: '${formatSom(result.annualLeakSom)} сом',
            subtitle: isRu ? 'Подписки × 12' : 'Жазылуулар × 12',
            icon: Icons.trending_up_rounded,
            accentColor: AppTheme.warmAmber,
            compact: isCompact,
          ),
          KpiCard(
            title: isCompact
                ? (isRu ? 'Битые строки' : 'Бузук сап')
                : (isRu ? 'Отброшено битых строк' : 'Бузулган саптар'),
            value: '${result.droppedRows.length}',
            subtitle: isRu ? 'Нажмите для лога' : 'Тизмени көрүү',
            icon: Icons.cleaning_services_rounded,
            accentColor: AppTheme.electricGreen,
            compact: isCompact,
            onTap: () => _showDroppedRowsDialog(context, result, isRu),
          ),
        ];

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: cards
              .map((c) => SizedBox(width: cardWidth, child: c))
              .toList(),
        );
      },
    );
  }

  Widget _buildAnalyticsCard(
    BuildContext context,
    AnalysisResult result,
    bool isRu,
  ) {
    final theme = Theme.of(context);
    final segments = isRu
        ? const ['По дням', 'Категории', 'Топ-5']
        : const ['Күндөр', 'Түзүмү', 'Топ-5'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: List<Widget>.generate(segments.length, (i) {
                  final selected = _analyticsTab == i;
                  return Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _analyticsTab = i),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.beelineYellow
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          segments[i],
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                            color: selected
                                ? AppTheme.obsidianBlack
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 14),
            if (_analyticsTab == 0)
              DailySpendChart(
                days: result.report.byDay,
                anomalies: result.anomalies,
                language: controller.language,
              )
            else if (_analyticsTab == 1)
              CategoryBreakdownChart(
                report: result.report,
                language: controller.language,
              )
            else
              _buildTopNumbersList(context, result, isRu),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleSummaryCard(
    BuildContext context,
    AnalysisResult result,
    bool isRu,
  ) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _auditExpanded = !_auditExpanded),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 20,
                      color: controller.llmUsedFallback
                          ? AppTheme.warmAmber
                          : AppTheme.electricGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isRu
                            ? 'Подробнее: AI-резюме и проверка Decimal'
                            : 'Толугураак: AI-корутунду жана Decimal текшерүү',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      _auditExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                    ),
                  ],
                ),
              ),
            ),
            if (_auditExpanded) ...[
              const Divider(height: 18),
              Text(
                controller.currentSummaryText,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: controller.isLoadingLlm
                        ? null
                        : () => _openLlmDialog(context, isRu),
                    icon: controller.isLoadingLlm
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_fix_high_rounded, size: 18),
                    label: Text(isRu ? 'AI-пояснение (опц.)' : 'AI түшүндүрмө'),
                  ),
                  Chip(
                    avatar: Icon(
                      controller.llmUsedLlm
                          ? Icons.psychology_rounded
                          : Icons.lock_rounded,
                      size: 16,
                      color: AppTheme.beelineYellow,
                    ),
                    label: Text(
                      controller.llmUsedLlm
                          ? (isRu
                              ? 'LLM проверено валидатором фактов'
                              : 'LLM фактылар менен текшерилди')
                          : controller.llmUsedFallback
                              ? (isRu
                                  ? 'LLM отклонено → точный шаблон'
                                  : 'LLM четке кагылды → так шаблон')
                              : (isRu
                                  ? 'Детерминированный расчёт (Decimal)'
                                  : 'Так эсептөө (Decimal)'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopNumbersList(
    BuildContext context,
    AnalysisResult result,
    bool isRu,
  ) {
    final theme = Theme.of(context);
    final top = result.report.topNumbers;
    if (top.isEmpty) {
      return Text(isRu ? 'Нет платных номеров' : 'Акы төлөнүүчү номерлер жок');
    }
    return Column(
      children: top
          .map(
            (item) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: item.isShortCode
                    ? AppTheme.coralRed.withValues(alpha: 0.16)
                    : AppTheme.beelineYellow,
                child: Icon(
                  item.isShortCode
                      ? Icons.sms_failed_rounded
                      : Icons.phone_rounded,
                  size: 18,
                  color: item.isShortCode
                      ? AppTheme.coralRed
                      : AppTheme.obsidianBlack,
                ),
              ),
              title: Text(
                item.normalizedNumber,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${item.count} ${isRu ? "списаний" : "жолу"}'
                '${item.isShortCode ? (isRu ? " · Короткий номер" : " · Кыска номер") : ""}',
              ),
              trailing: Text(
                '${formatSom(item.totalSom)} сом',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Future<void> _showDroppedRowsDialog(
    BuildContext context,
    AnalysisResult result,
    bool isRu,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            isRu
                ? 'Отброшенные строки (${result.droppedRows.length})'
                : 'Өткөрүлгөн саптар (${result.droppedRows.length})',
          ),
          content: SizedBox(
            width: 560,
            child: result.droppedRows.isEmpty
                ? Text(
                    isRu
                        ? 'Все строки CSV прошли строгую валидацию.'
                        : 'Бардык саптар текшерүүдөн өттү.',
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: result.droppedRows.length,
                    separatorBuilder: (_, _) => const Divider(height: 12),
                    itemBuilder: (_, idx) {
                      final row = result.droppedRows[idx];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.beelineYellow,
                          foregroundColor: AppTheme.obsidianBlack,
                          child: Text(
                            '${row.rowNumber}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        title: Text(
                          '${row.reason.wireName} · ${AppStrings.dropReasonLabel(row.reason, controller.language)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          row.rawLine.isEmpty ? '<empty>' : row.rawLine,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            if (result.droppedRows.isNotEmpty)
              TextButton.icon(
                onPressed: () async {
                  await controller.exportDroppedRowsCsv();
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text('dropped_rows.csv'),
              ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(isRu ? 'Закрыть' : 'Жабуу'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openLlmDialog(BuildContext context, bool isRu) async {
    var provider = controller.llmConfig.provider == LlmProvider.none
        ? LlmProvider.gemini
        : controller.llmConfig.provider;
    final keyCtrl = TextEditingController(text: controller.llmConfig.apiKey);
    final modelCtrl = TextEditingController(
      text: controller.llmConfig.model,
    );
    final ollamaCtrl = TextEditingController(
      text: controller.llmConfig.ollamaBaseUrl,
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text(
                isRu
                    ? 'Опциональное LLM-пояснение'
                    : 'Кошумча LLM түшүндүрмө',
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<LlmProvider>(
                      segments: const [
                        ButtonSegment(
                          value: LlmProvider.gemini,
                          label: Text('Gemini'),
                        ),
                        ButtonSegment(
                          value: LlmProvider.ollama,
                          label: Text('Ollama'),
                        ),
                        ButtonSegment(
                          value: LlmProvider.none,
                          label: Text('Offline'),
                        ),
                      ],
                      selected: <LlmProvider>{provider},
                      onSelectionChanged: (s) => setState(() {
                        provider = s.first;
                        if (provider == LlmProvider.ollama &&
                            modelCtrl.text == 'gemini-2.5-flash') {
                          modelCtrl.text = 'llama3.2';
                        } else if (provider == LlmProvider.gemini &&
                            modelCtrl.text == 'llama3.2') {
                          modelCtrl.text = 'gemini-2.5-flash';
                        }
                      }),
                    ),
                    const SizedBox(height: 12),
                    if (provider == LlmProvider.gemini) ...[
                      TextField(
                        controller: keyCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Gemini API Key',
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (provider == LlmProvider.ollama) ...[
                      TextField(
                        controller: ollamaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Ollama URL',
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (provider != LlmProvider.none)
                      TextField(
                        controller: modelCtrl,
                        decoration: const InputDecoration(labelText: 'Model'),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(isRu ? 'Отмена' : 'Жокко чыгаруу'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    controller.runLlmSummary(
                      LlmConfig(
                        provider: provider,
                        apiKey: keyCtrl.text,
                        model: modelCtrl.text.trim().isEmpty
                            ? 'gemini-2.5-flash'
                            : modelCtrl.text.trim(),
                        ollamaBaseUrl: ollamaCtrl.text.trim(),
                      ),
                    );
                  },
                  child: Text(isRu ? 'Сгенерировать' : 'Түзүү'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
