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
import '../widgets/senior_dashboard_view.dart';
import '../widgets/stories_recap_modal.dart';

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
                  Icons.bolt_rounded,
                  size: 44,
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
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStoriesStrip(context, result, isRu),
            const SizedBox(height: 14),
            _buildHeroBalanceCard(context, result, isRu),
            const SizedBox(height: 12),
            _buildBentoMetrics(context, result, isRu),
            const SizedBox(height: 12),
            _buildAnalyticsCard(context, result, isRu),
            const SizedBox(height: 12),
            _buildCollapsibleSummaryCard(context, result, isRu),
          ],
        ),
      ),
    );
  }

  Widget _buildStoriesStrip(
    BuildContext context,
    AnalysisResult result,
    bool isRu,
  ) {
    final bestTariff = controller.tariffRecommendations.isNotEmpty
        ? controller.tariffRecommendations.first
        : null;
    final yearlySavings = bestTariff?.yearlySavingsSom ?? Decimal.zero;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = <({IconData icon, String title, Color accent, int slide})>[
      (
        icon: Icons.bar_chart_rounded,
        title: isRu ? 'Итоги\nмесяца' : 'Айлык\nжыйынтык',
        accent: AppTheme.beelineYellow,
        slide: 0,
      ),
      (
        icon: Icons.bolt_rounded,
        title: isRu
            ? '${result.anomalies.length} утечек\n${formatSom(result.totalOverchargeSom)} с'
            : '${result.anomalies.length} жоготуу\n${formatSom(result.totalOverchargeSom)} с',
        accent: AppTheme.coralRed,
        slide: 1,
      ),
      (
        icon: Icons.savings_rounded,
        title: isRu
            ? 'Экономия\n${formatSom(yearlySavings)} с'
            : 'Үнөм\n${formatSom(yearlySavings)} с',
        accent: AppTheme.electricGreen,
        slide: 2,
      ),
      (
        icon: Icons.people_alt_rounded,
        title: isRu
            ? 'Семья:\n${controller.familyMembers.length} ном.'
            : 'Үй-бүлө:\n${controller.familyMembers.length} ном.',
        accent: AppTheme.beelineYellow,
        slide: 3,
      ),
    ];

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, idx) {
          final item = items[idx];
          return InkWell(
            onTap: () => showStoriesRecap(
              context,
              result: result,
              language: controller.language,
              bestTariff: bestTariff,
              onOpenClaim: () => controller.setTabIndex(4),
              initialSlide: item.slide,
            ),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 86,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.beelineYellow,
                    item.accent.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF151518) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(item.icon, size: 18, color: item.accent),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.obsidianBlack,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroBalanceCard(
    BuildContext context,
    AnalysisResult result,
    bool isRu,
  ) {
    final bestTariff = controller.tariffRecommendations.isNotEmpty
        ? controller.tariffRecommendations.first
        : null;
    final mascotInfo = BeeMascot.fromAnalysis(
      result: result,
      language: controller.language,
      bestTariff: bestTariff,
    );
    final hasOvercharge = result.totalOverchargeSom > Decimal.zero;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.carbonSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRu
                            ? 'Расходы за ${result.report.periodDays} дней'
                            : '${result.report.periodDays} күндүк чыгым',
                        style: const TextStyle(
                          color: AppTheme.coolGray,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${formatSom(result.report.totalSpendSom)} сом',
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                BeeMascot(
                  state: mascotInfo.state,
                  size: 56,
                  showBubble: false,
                  language: controller.language,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                InkWell(
                  onTap: () =>
                      controller.setTabIndex(hasOvercharge ? 1 : 3),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.carbonElevated,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: hasOvercharge
                                ? AppTheme.coralRed
                                : AppTheme.electricGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            hasOvercharge
                                ? (isRu
                                    ? 'Вернуть ${formatSom(result.totalOverchargeSom)} сом →'
                                    : '${formatSom(result.totalOverchargeSom)} сом кайтаруу →')
                                : (isRu ? 'Баланс чист ✓' : 'Баланс таза ✓'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: hasOvercharge
                                  ? AppTheme.coralRed
                                  : AppTheme.electricGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.beelineYellow,
                    foregroundColor: AppTheme.obsidianBlack,
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onPressed: controller.loadCustomCsvForActiveMember,
                  icon: const Icon(Icons.upload_file_rounded, size: 16),
                  label: Text(isRu ? 'Загрузить CSV' : 'CSV жүктөө'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoMetrics(
    BuildContext context,
    AnalysisResult result,
    bool isRu,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.carbonSurface : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFE5E5EC);

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppTheme.warmAmber,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isRu ? 'Прогноз утечки' : 'Жылдык жоготуу',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${formatSom(result.annualLeakSom)} сом/${isRu ? "год" : "жыл"}',
                    maxLines: 1,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: () => _showDroppedRowsDialog(context, result, isRu),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isRu ? 'Очистка CSV' : 'CSV тазалоо',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isRu
                          ? '${result.droppedRows.length} битые строки'
                          : '${result.droppedRows.length} бузук сап',
                      maxLines: 1,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(
    BuildContext context,
    AnalysisResult result,
    bool isRu,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final segments = isRu
        ? const ['По дням', 'Категории', 'Топ-5']
        : const ['Күндөр', 'Түзүмү', 'Топ-5'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF111114)
                    : const Color(0xFFF0F0F4),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: List<Widget>.generate(segments.length, (i) {
                  final selected = _analyticsTab == i;
                  return Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _analyticsTab = i),
                      borderRadius: BorderRadius.circular(999),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.beelineYellow
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
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
