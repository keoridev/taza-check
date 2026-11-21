import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../core/engine/llm_service.dart';
import '../../core/utils/decimal_utils.dart';
import '../../domain/entities/analysis_result.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_som_text.dart';
import '../widgets/bee_mascot.dart';
import '../widgets/category_breakdown_chart.dart';
import '../widgets/daily_spend_chart.dart';
import '../widgets/guide_stories_modal.dart';
import '../widgets/operator_logo.dart';
import '../widgets/senior_dashboard_view.dart';
import '../widgets/stories_recap_modal.dart';
import 'anomalies_screen.dart';

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
    final lang = controller.language;
    final tr = AppStrings.tr;

    if (controller.isBusy && result == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: BeeMascot(
            state: MascotState.loader,
            size: 112,
            language: lang,
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
                tr(
                  lang,
                  ru: 'Загрузите CSV детализацию или встроенное демо',
                  ky: 'CSV детализацияны же орнотулган демону жүктөңүз',
                  en: 'Load a CSV bill or try the built-in family demo',
                ),
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
                    label: Text(
                      tr(lang, ru: 'Загрузить CSV', ky: 'CSV жүктөө', en: 'Load CSV'),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.loadDemoFamily,
                    icon: const Icon(Icons.groups_rounded),
                    label: Text(
                      tr(
                        lang,
                        ru: 'Загрузить встроенное демо (5 абонентов)',
                        ky: 'Демо жүктөө (5 абонент)',
                        en: 'Load built-in demo (5 lines)',
                      ),
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
            _buildStoriesStrip(context, result, lang),
            const SizedBox(height: 14),
            _buildHeroBalanceCard(context, result, lang),
            const SizedBox(height: 12),
            _buildBentoMetrics(context, result, lang),
            const SizedBox(height: 12),
            _buildAnalyticsCard(context, result, lang),
            const SizedBox(height: 12),
            _buildCollapsibleSummaryCard(context, result, lang),
          ],
        ),
      ),
    );
  }

  String _formatCompactSom(Decimal value) {
    final rounded = value.round(scale: 0).toBigInt().toString();
    final buf = StringBuffer();
    for (var i = 0; i < rounded.length; i++) {
      if (i > 0 && (rounded.length - i) % 3 == 0) {
        buf.write(' ');
      }
      buf.write(rounded[i]);
    }
    return buf.toString();
  }

  Widget _buildStoriesStrip(
    BuildContext context,
    AnalysisResult result,
    AppLanguage lang,
  ) {
    final tr = AppStrings.tr;
    final shortCur = tr(lang, ru: 'с', ky: 'с', en: 'KGS');
    final bestTariff = controller.tariffRecommendations.isNotEmpty
        ? controller.tariffRecommendations.first
        : null;
    final yearlySavings = bestTariff?.yearlySavingsSom ?? Decimal.zero;
    final cur = result.report.totalSpendSom.toDouble();
    final opt = bestTariff?.estimatedMonthlyCostSom.toDouble() ?? cur;
    final discountPct = cur > opt && cur > 0
        ? (((cur - opt) / cur) * 100).round()
        : 80;

    final overchargeCompact = _formatCompactSom(result.totalOverchargeSom);
    final savingsCompact = _formatCompactSom(yearlySavings);

    final cards = <({
      String title,
      Color ringAccent,
      List<Color> gradientColors,
      Widget artwork,
      VoidCallback onOpen,
    })>[
      (
        title: tr(
          lang,
          ru: 'Итоги\nмесяца',
          ky: 'Айлык\nжыйынтык',
          en: 'Monthly\nrecap',
        ),
        ringAccent: AppTheme.beelineYellow,
        gradientColors: const [Color(0xFF4A3800), Color(0xFF14120A)],
        onOpen: () => showStoriesRecap(
          context,
          result: result,
          language: lang,
          bestTariff: bestTariff,
          onOpenClaim: () => controller.setTabIndex(4),
          initialSlide: 0,
        ),
        artwork: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 8,
              top: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final h in const [10.0, 18.0, 14.0, 26.0])
                    Container(
                      width: 5,
                      height: h,
                      margin: const EdgeInsets.only(right: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              right: -6,
              top: 4,
              child: Transform.rotate(
                angle: -0.08,
                child: Image.asset(
                  'assets/mascot/bee_detective.png',
                  width: 64,
                  height: 64,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
      (
        title: tr(
          lang,
          ru: '${result.anomalies.length} утечек\n$overchargeCompact $shortCur',
          ky: '${result.anomalies.length} жоготуу\n$overchargeCompact $shortCur',
          en: '${result.anomalies.length} leaks\n$overchargeCompact $shortCur',
        ),
        ringAccent: AppTheme.coralRed,
        gradientColors: const [Color(0xFF4E1116), Color(0xFF160B0C)],
        onOpen: () => showStoriesRecap(
          context,
          result: result,
          language: lang,
          bestTariff: bestTariff,
          onOpenClaim: () => controller.setTabIndex(4),
          initialSlide: 1,
        ),
        artwork: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -12,
              top: -8,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.coralRed.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -2,
              top: 2,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.coralRed.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -4,
              top: 4,
              child: Image.asset(
                'assets/mascot/bee_alert.png',
                width: 64,
                height: 64,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
      (
        title: tr(
          lang,
          ru: 'Экономия\n$savingsCompact $shortCur',
          ky: 'Үнөм\n$savingsCompact $shortCur',
          en: 'Save\n$savingsCompact $shortCur',
        ),
        ringAccent: AppTheme.electricGreen,
        gradientColors: const [Color(0xFF0C3D24), Color(0xFF0A140F)],
        onOpen: () => showStoriesRecap(
          context,
          result: result,
          language: lang,
          bestTariff: bestTariff,
          onOpenClaim: () => controller.setTabIndex(4),
          initialSlide: 2,
        ),
        artwork: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '−$discountPct%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -4,
              top: 6,
              child: Image.asset(
                'assets/mascot/bee_happy.png',
                width: 64,
                height: 64,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
      (
        title: tr(
          lang,
          ru: 'Семья:\n${controller.familyMembers.length} ном.',
          ky: 'Үй-бүлө:\n${controller.familyMembers.length} ном.',
          en: 'Family:\n${controller.familyMembers.length} lines',
        ),
        ringAccent: AppTheme.beelineYellow,
        gradientColors: const [Color(0xFF23194F), Color(0xFF0E0C1A)],
        onOpen: () => showStoriesRecap(
          context,
          result: result,
          language: lang,
          bestTariff: bestTariff,
          onOpenClaim: () => controller.setTabIndex(4),
          initialSlide: 3,
        ),
        artwork: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(
              left: 8,
              top: 8,
              child: SizedBox(
                width: 34,
                height: 16,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      child: OperatorLogo(operatorName: 'O!', size: 15),
                    ),
                    Positioned(
                      left: 9,
                      child: OperatorLogo(operatorName: 'Mega', size: 15),
                    ),
                    Positioned(
                      left: 18,
                      child: OperatorLogo(operatorName: 'Beeline', size: 15),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -6,
              top: 10,
              child: Image.asset(
                'assets/mascot/bee_senior.png',
                width: 58,
                height: 58,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
      (
        title: tr(
          lang,
          ru: 'Обучалка\nдля семьи',
          ky: 'Колдонмо\nүй-бүлөгө',
          en: 'Family\nguide',
        ),
        ringAccent: AppTheme.beelineYellow,
        gradientColors: const [Color(0xFF624A00), Color(0xFF171307)],
        onOpen: () => showGuideStories(
          context,
          language: lang,
          onEnableSeniorMode: () => controller.toggleSeniorMode(true),
        ),
        artwork: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.beelineYellow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      size: 10,
                      color: AppTheme.obsidianBlack,
                    ),
                    Text(
                      tr(lang, ru: 'ГИД', ky: 'ГИД', en: 'GUIDE'),
                      style: const TextStyle(
                        color: AppTheme.obsidianBlack,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -6,
              top: 8,
              child: Image.asset(
                'assets/mascot/bee_loader.png',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    ];

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, idx) {
          final card = cards[idx];
          return _PressableScale(
            onTap: () {
              HapticFeedback.selectionClick();
              card.onOpen();
            },
            child: Container(
              width: 88,
              height: 110,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.beelineYellow,
                    card.ringAccent.withValues(alpha: 0.75),
                  ],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.4, -0.4),
                          radius: 1.1,
                          colors: card.gradientColors,
                        ),
                      ),
                    ),
                    card.artwork,
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.42, 1.0],
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.85),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Text(
                        card.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                        ),
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
    AppLanguage lang,
  ) {
    final tr = AppStrings.tr;
    final cur = AppStrings.currency(lang);
    final bestTariff = controller.tariffRecommendations.isNotEmpty
        ? controller.tariffRecommendations.first
        : null;
    final mascotInfo = BeeMascot.fromAnalysis(
      result: result,
      language: lang,
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
                        tr(
                          lang,
                          ru: 'Расходы за ${result.report.periodDays} дней',
                          ky: '${result.report.periodDays} күндүк чыгым',
                          en: 'Spend over ${result.report.periodDays} days',
                        ),
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
                        child: AnimatedSomText(
                          amount: result.report.totalSpendSom,
                          suffix: ' $cur',
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
                  language: lang,
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => controller.setTabIndex(hasOvercharge ? 1 : 3),
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
                            ? tr(
                                lang,
                                ru: 'Вернуть ${formatSom(result.totalOverchargeSom)} сом →',
                                ky: '${formatSom(result.totalOverchargeSom)} сом кайтаруу →',
                                en: 'Reclaim ${formatSom(result.totalOverchargeSom)} $cur →',
                              )
                            : tr(
                                lang,
                                ru: 'Баланс чист ✓',
                                ky: 'Баланс таза ✓',
                                en: 'Balance is clean ✓',
                              ),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.beelineYellow,
                      foregroundColor: AppTheme.obsidianBlack,
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onPressed: controller.loadCustomCsvForActiveMember,
                    icon: const Icon(Icons.upload_file_rounded, size: 16),
                    label: Text(
                      tr(lang, ru: 'Загрузить CSV', ky: 'CSV жүктөө', en: 'Load CSV'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppTheme.carbonElevated,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () => AnomaliesScreen.showSmsInterceptSheet(
                    context,
                    language: lang,
                  ),
                  icon: const Icon(Icons.sms_failed_rounded, size: 16),
                  label: Text(
                    tr(lang, ru: 'Тест SMS', ky: 'SMS тест', en: 'Test SMS'),
                  ),
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
    AppLanguage lang,
  ) {
    final theme = Theme.of(context);
    final tr = AppStrings.tr;
    final cur = AppStrings.currency(lang);
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
                        tr(
                          lang,
                          ru: 'Прогноз утечки',
                          ky: 'Жылдык жоготуу',
                          en: 'Leak forecast',
                        ),
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
                    '${formatSom(result.annualLeakSom)} $cur/${tr(lang, ru: "год", ky: "жыл", en: "yr")}',
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
            onTap: () => _showDroppedRowsDialog(context, result, lang),
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
                          tr(
                            lang,
                            ru: 'Очистка CSV',
                            ky: 'CSV тазалоо',
                            en: 'CSV cleanup',
                          ),
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
                      tr(
                        lang,
                        ru: '${result.droppedRows.length} битые строки',
                        ky: '${result.droppedRows.length} бузук сап',
                        en: '${result.droppedRows.length} bad rows',
                      ),
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
    AppLanguage lang,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final segments = switch (lang) {
      AppLanguage.ru => const ['По дням', 'Категории', 'Топ-5'],
      AppLanguage.ky => const ['Күндөр', 'Түзүмү', 'Топ-5'],
      AppLanguage.en => const ['Daily', 'Categories', 'Top 5'],
    };

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
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _analyticsTab = i);
                      },
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
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey<int>(_analyticsTab),
                child: _analyticsTab == 0
                    ? DailySpendChart(
                        days: result.report.byDay,
                        anomalies: result.anomalies,
                        language: lang,
                      )
                    : (_analyticsTab == 1
                        ? CategoryBreakdownChart(
                            report: result.report,
                            language: lang,
                          )
                        : _buildTopNumbersList(context, result, lang)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleSummaryCard(
    BuildContext context,
    AnalysisResult result,
    AppLanguage lang,
  ) {
    final theme = Theme.of(context);
    final tr = AppStrings.tr;
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
                        tr(
                          lang,
                          ru: 'Подробнее: AI-резюме и проверка Decimal',
                          ky: 'Толугураак: AI-корутунду жана Decimal текшерүү',
                          en: 'Details: AI summary & Decimal audit',
                        ),
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
                        : () => _openLlmDialog(context, lang),
                    icon: controller.isLoadingLlm
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_fix_high_rounded, size: 18),
                    label: Text(
                      tr(
                        lang,
                        ru: 'AI-пояснение (опц.)',
                        ky: 'AI түшүндүрмө',
                        en: 'AI explanation (opt.)',
                      ),
                    ),
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
                          ? tr(
                              lang,
                              ru: 'LLM проверено валидатором фактов',
                              ky: 'LLM фактылар менен текшерилди',
                              en: 'LLM verified by fact-validator',
                            )
                          : controller.llmUsedFallback
                              ? tr(
                                  lang,
                                  ru: 'LLM отклонено → точный шаблон',
                                  ky: 'LLM четке кагылды → так шаблон',
                                  en: 'LLM rejected → exact template',
                                )
                              : tr(
                                  lang,
                                  ru: 'Детерминированный расчёт (Decimal)',
                                  ky: 'Так эсептөө (Decimal)',
                                  en: 'Deterministic Decimal math',
                                ),
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
    AppLanguage lang,
  ) {
    final theme = Theme.of(context);
    final tr = AppStrings.tr;
    final cur = AppStrings.currency(lang);
    final top = result.report.topNumbers;
    if (top.isEmpty) {
      return Text(
        tr(
          lang,
          ru: 'Нет платных номеров',
          ky: 'Акы төлөнүүчү номерлер жок',
          en: 'No paid numbers found',
        ),
      );
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
                '${item.count} ${tr(lang, ru: "списаний", ky: "жолу", en: "charges")}'
                '${item.isShortCode ? " · ${tr(lang, ru: "Короткий номер", ky: "Кыска номер", en: "Short code")}" : ""}',
              ),
              trailing: Text(
                '${formatSom(item.totalSom)} $cur',
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
    AppLanguage lang,
  ) async {
    final tr = AppStrings.tr;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            tr(
              lang,
              ru: 'Отброшенные строки (${result.droppedRows.length})',
              ky: 'Өткөрүлгөн саптар (${result.droppedRows.length})',
              en: 'Dropped rows (${result.droppedRows.length})',
            ),
          ),
          content: SizedBox(
            width: 560,
            child: result.droppedRows.isEmpty
                ? Text(
                    tr(
                      lang,
                      ru: 'Все строки CSV прошли строгую валидацию.',
                      ky: 'Бардык саптар текшерүүдөн өттү.',
                      en: 'Every CSV row passed strict validation.',
                    ),
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
                          '${row.reason.wireName} · ${AppStrings.dropReasonLabel(row.reason, lang)}',
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
              child: Text(tr(lang, ru: 'Закрыть', ky: 'Жабуу', en: 'Close')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openLlmDialog(BuildContext context, AppLanguage lang) async {
    final tr = AppStrings.tr;
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
                tr(
                  lang,
                  ru: 'Опциональное LLM-пояснение',
                  ky: 'Кошумча LLM түшүндүрмө',
                  en: 'Optional LLM explanation',
                ),
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
                  child: Text(
                    tr(lang, ru: 'Отмена', ky: 'Жокко чыгаруу', en: 'Cancel'),
                  ),
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
                  child: Text(
                    tr(lang, ru: 'Сгенерировать', ky: 'Түзүү', en: 'Generate'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PressableScale extends StatefulWidget {
  const _PressableScale({
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
