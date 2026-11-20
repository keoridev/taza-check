import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/decimal_utils.dart';
import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/anomaly.dart';
import '../../domain/entities/tariff_plan.dart';
import '../theme/app_theme.dart';
import 'bee_mascot.dart';

/// Opens the full-screen Kaspi/Instagram-style «Итоги месяца в Stories» recap.
Future<void> showStoriesRecap(
  BuildContext context, {
  required AnalysisResult result,
  required AppLanguage language,
  TariffRecommendation? bestTariff,
  required VoidCallback onOpenClaim,
  int initialSlide = 0,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Stories',
    barrierColor: Colors.black87,
    pageBuilder: (ctx, _, _) => _StoriesRecapView(
      result: result,
      language: language,
      bestTariff: bestTariff,
      onOpenClaim: onOpenClaim,
      initialSlide: initialSlide,
    ),
  );
}

class _StoriesRecapView extends StatefulWidget {
  const _StoriesRecapView({
    required this.result,
    required this.language,
    required this.bestTariff,
    required this.onOpenClaim,
    this.initialSlide = 0,
  });

  final AnalysisResult result;
  final AppLanguage language;
  final TariffRecommendation? bestTariff;
  final VoidCallback onOpenClaim;
  final int initialSlide;

  @override
  State<_StoriesRecapView> createState() => _StoriesRecapViewState();
}

class _StoriesRecapViewState extends State<_StoriesRecapView> {
  late int _index;
  static const int _totalSlides = 4;

  @override
  void initState() {
    super.initState();
    _index = widget.initialSlide.clamp(0, _totalSlides - 1);
  }

  void _next() {
    if (_index < _totalSlides - 1) {
      setState(() => _index++);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prev() {
    if (_index > 0) {
      setState(() => _index--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRu = widget.language == AppLanguage.ru;
    final result = widget.result;
    final gbUsed = divToDecimal(
      result.report.totalDataMb,
      Decimal.fromInt(1024),
      scale: 2,
    );

    final sortedAnomalies = List<Anomaly>.from(result.anomalies)
      ..sort((a, b) => b.costSom.compareTo(a.costSom));
    final topThreat = sortedAnomalies.isNotEmpty ? sortedAnomalies.first : null;
    final yearlyTariffSavings =
        widget.bestTariff?.yearlySavingsSom ?? Decimal.zero;
    final combinedBenefit = result.totalOverchargeSom + yearlyTariffSavings;

    final slides = <({
      MascotState mascotState,
      String tag,
      String title,
      String metric,
      String description,
      Color accent,
    })>[
      (
        mascotState: MascotState.detective,
        tag: isRu ? 'СЛАЙД 1 · МЕСЯЦ В ЦИФРАХ' : '1-СЛАЙД · БИР АЙ САНДАРДА',
        title: isRu ? 'Твой месяц в цифрах' : 'Сенин айың сандарда',
        metric: '${formatSom(result.report.totalSpendSom)} сом',
        description: isRu
            ? '${result.report.totalCallMinutes.toStringAsFixed(0)} мин звонков · '
                '${gbUsed.toStringAsFixed(1)} ГБ интернета · '
                'очищено ${result.droppedRows.length} битых строк CSV.'
            : '${result.report.totalCallMinutes.toStringAsFixed(0)} мүн чалуу · '
                '${gbUsed.toStringAsFixed(1)} ГБ интернет · '
                '${result.droppedRows.length} бузук сап тазаланды.',
        accent: AppTheme.beelineYellow,
      ),
      (
        mascotState: topThreat != null ? MascotState.alert : MascotState.happy,
        tag: isRu ? 'СЛАЙД 2 · ГЛАВНАЯ УТЕЧКА' : '2-СЛАЙД · НЕГИЗГИ ЖОГОТУУ',
        title: isRu ? 'Главный пожиратель баланса' : 'Балансты эң көп жеген',
        metric: topThreat != null
            ? (topThreat.number?.isNotEmpty == true
                ? topThreat.number!
                : '${formatSom(topThreat.costSom)} сом')
            : (isRu ? '0 угроз' : '0 коркунуч'),
        description: topThreat != null
            ? (isRu ? topThreat.explanationRu : topThreat.explanationKy)
            : (isRu
                ? 'Скрытых подписок и аномальных всплесков не обнаружено!'
                : 'Жашыруун жазылуулар жана шектүү списаниелер табылган жок!'),
        accent: topThreat != null ? AppTheme.coralRed : AppTheme.electricGreen,
      ),
      (
        mascotState: MascotState.happy,
        tag: isRu ? 'СЛАЙД 3 · ВОЗВРАТ И ВЫГОДА' : '3-СЛАЙД · КАЙТАРУУ ЖАНА ПАЙДА',
        title: isRu ? 'Сколько можно вернуть' : 'Канча сом кайтарса болот',
        metric: '${formatSom(result.totalOverchargeSom)} сом',
        description: isRu
            ? 'Плюс экономия на тарифе: ${formatSom(yearlyTariffSavings)} сом/год. '
                'Итоговая годовая выгода: ${formatSom(combinedBenefit)} сом!'
            : 'Тарифтен үнөм: ${formatSom(yearlyTariffSavings)} сом/жыл. '
                'Жалпы жылдык пайда: ${formatSom(combinedBenefit)} сом!',
        accent: AppTheme.electricGreen,
      ),
      (
        mascotState: result.totalOverchargeSom > Decimal.zero
            ? MascotState.alert
            : MascotState.happy,
        tag: isRu ? 'СЛАЙД 4 · ВЕРДИКТ ЗАЩИТЫ' : '4-СЛАЙД · КОРГОО КОРУТУНДУСУ',
        title: isRu ? 'Вердикт защиты' : 'Коргоо чечими',
        metric: result.totalOverchargeSom > Decimal.zero
            ? (isRu ? 'Пора действовать!' : 'Аракет кылуу керек!')
            : (isRu ? 'Баланс под щитом' : 'Баланс коргоодо'),
        description: isRu
            ? 'Сформируйте юридическую претензию в 1 клик или отправьте отчёт семье.'
            : '1 баскыч менен юридикалык арыз түзүңүз же үй-бүлөгө жөнөтүңүз.',
        accent: AppTheme.beelineYellow,
      ),
    ];

    final slide = slides[_index];

    return Material(
      color: AppTheme.obsidianBlack,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.carbonSurface,
                    slide.accent.withValues(alpha: 0.14),
                    AppTheme.obsidianBlack,
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: slide.accent.withValues(alpha: 0.6),
                  width: 1.8,
                ),
              ),
              child: Stack(
                children: [
                  // Tap zones for left/right story navigation
                  Positioned.fill(
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: _prev,
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: _next,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Segmented progress bars
                        Row(
                          children: List<Widget>.generate(_totalSlides, (i) {
                            return Expanded(
                              child: Container(
                                height: 4,
                                margin: EdgeInsets.only(
                                  right: i < _totalSlides - 1 ? 6 : 0,
                                ),
                                decoration: BoxDecoration(
                                  color: i <= _index
                                      ? AppTheme.beelineYellow
                                      : Colors.white24,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                slide.tag,
                                style: TextStyle(
                                  color: slide.accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Center(
                          child: BeeMascot(
                            state: slide.mascotState,
                            size: 112,
                            showBubble: false,
                            language: widget.language,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            slide.metric,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: slide.accent,
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.carbonSurface.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.carbonBorder),
                          ),
                          child: Text(
                            slide.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.45,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (_index == _totalSlides - 1) ...[
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              widget.onOpenClaim();
                            },
                            icon: const Icon(Icons.description_rounded),
                            label: Text(
                              isRu
                                  ? 'Сформировать претензию'
                                  : 'Арыз түзүү',
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: AppTheme.beelineYellow),
                            ),
                            onPressed: () async {
                              final shareText = isRu
                                  ? 'Отчёт «Где мои деньги?»: траты ${formatSom(result.report.totalSpendSom)} сом, к возврату ${formatSom(result.totalOverchargeSom)} сом.'
                                  : '«Менин акчам кайда?» отчёту: чыгым ${formatSom(result.report.totalSpendSom)} сом, кайтаруу ${formatSom(result.totalOverchargeSom)} сом.';
                              await Clipboard.setData(
                                ClipboardData(text: shareText),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isRu
                                          ? 'Итоги скопированы для семейного чата'
                                          : 'Жыйынтык үй-бүлөлүк чат үчүн көчүрүлдү',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.share_rounded),
                            label: Text(
                              isRu
                                  ? 'Поделиться в семейный чат'
                                  : 'Үй-бүлөлүк чатка бөлүшүү',
                            ),
                          ),
                        ] else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: _index > 0 ? _prev : null,
                                child: Text(isRu ? '← Назад' : '← Артка'),
                              ),
                              FilledButton(
                                onPressed: _next,
                                child: Text(isRu ? 'Далее →' : 'Кийинки →'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
