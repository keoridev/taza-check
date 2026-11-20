import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/engine/llm_service.dart';
import '../../core/utils/decimal_utils.dart';
import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/anomaly.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/category_breakdown_chart.dart';
import '../widgets/daily_spend_chart.dart';
import '../widgets/kpi_card.dart';
import '../widgets/senior_dashboard_view.dart';

/// Main overview screen (`Обзор`): Telecom Balance hero card, 4 KPI cards,
/// daily spend chart, category donut, top-5 numbers, and anti-hallucination AI card.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final result = controller.activeResult;
    final isRu = controller.language == AppLanguage.ru;

    if (controller.isBusy && result == null) {
      return const Center(child: CircularProgressIndicator());
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
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeroBalanceCard(context, result, isRu),
          const SizedBox(height: 16),
          _buildKpiGrid(context, result, isRu),
          const SizedBox(height: 16),
          _buildSummaryCard(context, result, isRu),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildDailyChartCard(context, result, isRu),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildCategoryCard(context, result, isRu),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  _buildDailyChartCard(context, result, isRu),
                  const SizedBox(height: 16),
                  _buildCategoryCard(context, result, isRu),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _buildTopNumbersCard(context, result, isRu),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
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
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.carbonBorder),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -32,
              top: -28,
              child: Transform.rotate(
                angle: -0.45,
                child: Container(
                  width: 120,
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.beelineYellow.withValues(alpha: 0.22),
                        AppTheme.beelineYellow.withValues(alpha: 0.04),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 28,
              top: -40,
              child: Transform.rotate(
                angle: -0.45,
                child: Container(
                  width: 24,
                  height: 220,
                  color: AppTheme.beelineYellow.withValues(alpha: 0.16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
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
                                fontSize: 12,
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
                              fontSize: 18,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${member?.phone ?? ""} · ${result.sourceName} · '
                        '${result.records.length} ${isRu ? "строк" : "сап"} · '
                        '${result.report.periodDays} ${isRu ? "дн." : "күн"}',
                        style: const TextStyle(
                          color: AppTheme.coolGray,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: controller.loadCustomCsvForActiveMember,
                        icon: const Icon(Icons.upload_file_rounded, size: 18),
                        label: Text(isRu ? 'Загрузить CSV' : 'CSV жүктөө'),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                            color: Color(0xFF3A3A44),
                            width: 1.5,
                          ),
                        ),
                        onPressed: controller.loadDemoFamily,
                        icon: const Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: AppTheme.beelineYellow,
                        ),
                        label: Text(
                          isRu
                              ? 'Загрузить встроенное демо (5 абонентов)'
                              : 'Орнотулган демо (5 абонент)',
                        ),
                      ),
                    ],
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
    final cards = <Widget>[
      KpiCard(
        title: isRu ? 'Всего потрачено' : 'Жалпы сарпталды',
        value: '${formatSom(result.report.totalSpendSom)} сом',
        subtitle:
            '${result.records.length} ${isRu ? "операций за период" : "операция"}',
        icon: Icons.account_balance_wallet_rounded,
        accentColor: AppTheme.beelineYellow,
      ),
      KpiCard(
        title: isRu ? 'Возможная переплата' : 'Мүмкүн ашыкча төлөм',
        value: '${formatSom(result.totalOverchargeSom)} сом',
        subtitle:
            '${result.anomalies.length} ${isRu ? "аномалий (без двойного учёта)" : "аномалия"}',
        icon: Icons.gpp_maybe_rounded,
        accentColor: result.totalOverchargeSom > Decimal.zero
            ? AppTheme.coralRed
            : AppTheme.electricGreen,
        onTap: () => controller.setTabIndex(1),
      ),
      KpiCard(
        title: isRu
            ? 'Прогноз утечки за год (подписки × 12)'
            : 'Жылдык жоготуу (жазылуу × 12)',
        value: '${formatSom(result.annualLeakSom)} сом',
        subtitle: isRu
            ? 'Подписки и контент-услуги'
            : 'Жазылуулар жана контент',
        icon: Icons.trending_up_rounded,
        accentColor: AppTheme.warmAmber,
      ),
      KpiCard(
        title: isRu ? 'Отброшено битых строк' : 'Бузулган саптар',
        value: '${result.droppedRows.length}',
        subtitle: isRu
            ? 'Нажмите для просмотра лога'
            : 'Тизмени көрүү үчүн басыңыз',
        icon: Icons.cleaning_services_rounded,
        accentColor: AppTheme.electricGreen,
        onTap: () => _showDroppedRowsDialog(context, result, isRu),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final crossCount = w >= 1000 ? 4 : (w >= 560 ? 2 : 1);
        final cardWidth = (w - (crossCount - 1) * 12) / crossCount;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map(
                (c) => SizedBox(
                  width: cardWidth,
                  child: c,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    AnalysisResult result,
    bool isRu,
  ) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: controller.llmUsedFallback
                          ? AppTheme.warmAmber
                          : AppTheme.electricGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isRu
                          ? 'Резюме аудита (защита от галлюцинаций)'
                          : 'Аудит жыйынтыгы (галлюцинациядан коргоо)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
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
              ],
            ),
            const SizedBox(height: 10),
            Text(
              controller.currentSummaryText,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
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
                                ? 'LLM отклонено валидатором → детерминированный шаблон'
                                : 'LLM четке кагылды → так шаблон')
                            : (isRu
                                ? 'Детерминированный расчёт (Decimal)'
                                : 'Так эсептөө (Decimal)'),
                  ),
                ),
                if (controller.llmRejectionReasons.isNotEmpty)
                  Chip(
                    label: Text(
                      controller.llmRejectionReasons.take(2).join(', '),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChartCard(
    BuildContext context,
    AnalysisResult result,
    bool isRu,
  ) {
    final spikeCount =
        result.anomalies.where((a) => a.type == AnomalyType.daySpike).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRu
                  ? 'Расходы по дням (аномальные всплески: $spikeCount)'
                  : 'Күндүк чыгымдар (кескин өсүштөр: $spikeCount)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            DailySpendChart(
              days: result.report.byDay,
              anomalies: result.anomalies,
              language: controller.language,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    AnalysisResult result,
    bool isRu,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRu ? 'Структура расходов' : 'Чыгымдардын түзүмү',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            CategoryBreakdownChart(
              report: result.report,
              language: controller.language,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNumbersCard(
    BuildContext context,
    AnalysisResult result,
    bool isRu,
  ) {
    final theme = Theme.of(context);
    final top = result.report.topNumbers;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRu
                  ? 'Топ-5 самых затратных номеров (нормализовано)'
                  : 'Эң көп чыгым кеткен 5 номер',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (top.isEmpty)
              Text(isRu ? 'Нет платных номеров' : 'Акы төлөнүүчү номерлер жок')
            else
              ...top.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: item.isShortCode
                        ? AppTheme.coralRed.withValues(alpha: 0.16)
                        : AppTheme.beelineYellow,
                    child: Icon(
                      item.isShortCode
                          ? Icons.sms_failed_rounded
                          : Icons.phone_rounded,
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
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
