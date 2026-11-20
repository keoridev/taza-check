import 'dart:async';
import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/decimal_utils.dart';
import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/anomaly.dart';
import '../../domain/entities/tariff_plan.dart';
import '../theme/app_theme.dart';

/// Reactive visual states for the Beeline-inspired Bee mascot.
enum MascotState {
  loader,
  alert,
  happy,
  detective,
  seniorHelper,
}

/// Animated multi-state mascot built around `assets/mascot/bee_base.png`
/// with comic `#141418` outlines, wing-flutter/bobbing animations,
/// state badges, and contextual speech bubbles.
class BeeMascot extends StatefulWidget {
  const BeeMascot({
    super.key,
    required this.state,
    this.message,
    this.cyclingMessages,
    this.size = 96,
    this.showBubble = true,
    this.compact = false,
    this.language = AppLanguage.ru,
    this.onTap,
  });

  final MascotState state;
  final String? message;
  final List<String>? cyclingMessages;
  final double size;
  final bool showBubble;
  final bool compact;
  final AppLanguage language;
  final VoidCallback? onTap;

  static const Map<MascotState, String> _assetByState = <MascotState, String>{
    MascotState.loader: 'assets/mascot/bee_loader.png',
    MascotState.alert: 'assets/mascot/bee_alert.png',
    MascotState.happy: 'assets/mascot/bee_happy.png',
    MascotState.detective: 'assets/mascot/bee_detective.png',
    MascotState.seniorHelper: 'assets/mascot/bee_senior.png',
  };

  /// All mascot PNG asset paths for startup precaching.
  static Iterable<String> get allAssetPaths => _assetByState.values;

  /// Returns the dedicated PNG asset path for [state].
  static String assetForState(MascotState state) =>
      _assetByState[state] ?? 'assets/mascot/bee_base.png';

  /// Precaches all 5 mascot illustrations so state & tab switches are instant.
  static Future<void> precacheAll(BuildContext context) async {
    for (final path in allAssetPaths) {
      await precacheImage(AssetImage(path), context);
    }
  }

  /// Selects the best reactive mascot state & dynamic explanation for an [AnalysisResult].
  static ({MascotState state, String message, List<String> tips}) fromAnalysis({
    required AnalysisResult result,
    required AppLanguage language,
    TariffRecommendation? bestTariff,
  }) {
    final isRu = language == AppLanguage.ru;
    final overcharge = result.totalOverchargeSom;
    final droppedCount = result.droppedRows.length;

    final tips = isRu
        ? <String>[
            if (droppedCount > 0)
              'Я отфильтровал $droppedCount сломанных строк из CSV, чтобы расчёт был на 100% честным.',
            if (bestTariff != null && bestTariff.yearlySavingsSom > Decimal.zero)
              'Совет: смена тарифа на «${bestTariff.plan.name}» сэкономит ${formatSom(bestTariff.yearlySavingsSom)} сом в год!',
            'Совет: никогда не отправляйте «ДА» на короткие номера — для отписки шлите «СТОП».',
            'Совет: проверяйте ночные SMS с 00:00 до 06:00 — часто так маскируются платные подписки.',
          ]
        : <String>[
            if (droppedCount > 0)
              'Эсеп 100% так болушу үчүн CSV файлдан $droppedCount бузук сапты тазаладым.',
            if (bestTariff != null && bestTariff.yearlySavingsSom > Decimal.zero)
              'Кеңеш: «${bestTariff.plan.name}» тарифине өтсөңүз, жылына ${formatSom(bestTariff.yearlySavingsSom)} сом үнөмдөйсүз!',
            'Кеңеш: кыска номерлерге «ООБА» деп жооп бербеңиз — өчүрүү үчүн «СТОП» жөнөтүңүз.',
            'Кеңеш: түнкү 00:00–06:00 аралыгындагы SMS списаниелерди текшерип туруңуз.',
          ];

    if (overcharge > Decimal.zero && result.anomalies.isNotEmpty) {
      // Pick the highest-overcharge line-item anomaly (fallback to first anomaly).
      final sorted = List<Anomaly>.from(result.anomalies)
        ..sort((a, b) => b.overchargeSom.compareTo(a.overchargeSom));
      final top = sorted.first;
      final numberLabel = (top.number != null && top.number!.isNotEmpty)
          ? top.number!
          : (isRu ? 'неизвестный номер' : 'белгисиз номер');
      final amountText = formatSom(overcharge);

      final msg = isRu
          ? 'Осторожно! Номер $numberLabel тихо списывает деньги — можно вернуть $amountText сом!'
          : 'Абайлаңыз! $numberLabel номери акча алып жатат — $amountText сом кайтарса болот!';
      return (state: MascotState.alert, message: msg, tips: tips);
    }

    if (droppedCount > 0 &&
        (bestTariff == null || bestTariff.yearlySavingsSom <= Decimal.zero)) {
      final msg = isRu
          ? 'Я отфильтровал $droppedCount сломанных строк из CSV, чтобы расчёт был на 100% честным.'
          : 'Эсеп 100% так болушу үчүн CSV файлдан $droppedCount бузук сапты тазаладым.';
      return (state: MascotState.detective, message: msg, tips: tips);
    }

    final savingsText =
        (bestTariff != null && bestTariff.yearlySavingsSom > Decimal.zero)
            ? (isRu
                ? ', а смена тарифа сэкономит ${formatSom(bestTariff.yearlySavingsSom)} сом в год'
                : ', ал эми тарифти алмаштыруу жылына ${formatSom(bestTariff.yearlySavingsSom)} сом үнөмдөйт')
            : '';
    final msg = isRu
        ? 'Всё чисто! Лишних подписок нет$savingsText.'
        : 'Баары таза! Ашыкча жазылуулар жок$savingsText.';
    return (state: MascotState.happy, message: msg, tips: tips);
  }

  @override
  State<BeeMascot> createState() => _BeeMascotState();
}

class _BeeMascotState extends State<BeeMascot> with TickerProviderStateMixin {
  late final AnimationController _bobController;
  late final AnimationController _wingController;
  late final AnimationController _radarController;
  late final AnimationController _tapBounceController;

  Timer? _loaderTimer;
  int _loaderStep = 0;
  int _tipIndex = -1;

  static const List<String> _loaderMessagesRu = <String>[
    'Читаю детализацию...',
    'Отсеиваю битые строки и мусор...',
    'Проверяю ночные списания и подписки...',
    'Считаю точную сумму до копейки...',
  ];

  static const List<String> _loaderMessagesKy = <String>[
    'Детализацияны окуп жатам...',
    'Бузук саптарды тазалап жатам...',
    'Түнкү списаниелерди текшерип жатам...',
    'Тыйынына чейин так эсептеп жатам...',
  ];

  @override
  void initState() {
    super.initState();
    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _wingController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.state == MascotState.loader ? 170 : 420,
      ),
    )..repeat(reverse: true);

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _tapBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    _syncLoaderTimer();
  }

  @override
  void didUpdateWidget(covariant BeeMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _wingController.duration = Duration(
        milliseconds: widget.state == MascotState.loader ? 170 : 420,
      );
      if (_wingController.isAnimating) {
        _wingController.repeat(reverse: true);
      }
      _tipIndex = -1;
      _syncLoaderTimer();
    }
    if (oldWidget.message != widget.message) {
      _tipIndex = -1;
    }
  }

  void _syncLoaderTimer() {
    _loaderTimer?.cancel();
    _loaderTimer = null;
    if (widget.state == MascotState.loader) {
      _loaderStep = 0;
      _loaderTimer = Timer.periodic(
        const Duration(milliseconds: 1350),
        (_) {
          if (!mounted) return;
          setState(() {
            _loaderStep = (_loaderStep + 1) % _loaderMessagesRu.length;
          });
        },
      );
    }
  }

  @override
  void dispose() {
    _loaderTimer?.cancel();
    _bobController.dispose();
    _wingController.dispose();
    _radarController.dispose();
    _tapBounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _tapBounceController.forward(from: 0);
    final tips = widget.cyclingMessages;
    if (tips != null && tips.isNotEmpty) {
      setState(() {
        _tipIndex = (_tipIndex + 1) % (tips.length + 1) - 1;
        if (_tipIndex < 0) {
          _tipIndex = 0;
        }
      });
    }
    widget.onTap?.call();
  }

  String _resolvedMessage() {
    if (_tipIndex >= 0 &&
        widget.cyclingMessages != null &&
        _tipIndex < widget.cyclingMessages!.length) {
      return widget.cyclingMessages![_tipIndex];
    }
    if (widget.message != null && widget.message!.isNotEmpty) {
      return widget.message!;
    }
    final isRu = widget.language == AppLanguage.ru;
    return switch (widget.state) {
      MascotState.loader => isRu
          ? _loaderMessagesRu[_loaderStep]
          : _loaderMessagesKy[_loaderStep],
      MascotState.alert => isRu
          ? 'Внимание! Найдены подозрительные списания.'
          : 'Көңүл буруңуз! Шектүү списаниелер табылды.',
      MascotState.happy => isRu
          ? 'Всё чисто! Лишних подписок не обнаружено.'
          : 'Баары таза! Ашыкча жазылуулар табылган жок.',
      MascotState.detective => isRu
          ? 'Я отфильтровал повреждённые строки из CSV для точного расчёта.'
          : 'Так эсеп үчүн CSV файлдан бузук саптарды тазаладым.',
      MascotState.seniorHelper => isRu
          ? 'Не переживайте! Я проверил ваш баланс и всё объясню простыми словами.'
          : 'Кабатыр болбоңуз! Балансыңызды текшердим, баарын жөнөкөй тилде түшүндүрөм.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final msg = _resolvedMessage();
    if (widget.compact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildAnimatedCharacter(widget.size),
          if (widget.showBubble) ...[
            const SizedBox(width: 10),
            Expanded(child: _buildSpeechBubble(context, msg, compact: true)),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 340;
        if (narrow && widget.showBubble) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAnimatedCharacter(widget.size * 0.72),
              const SizedBox(width: 10),
              Expanded(child: _buildSpeechBubble(context, msg, compact: true)),
            ],
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.showBubble) ...[
              Flexible(
                child: _buildSpeechBubble(context, msg, compact: false),
              ),
              const SizedBox(width: 12),
            ],
            _buildAnimatedCharacter(widget.size),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedCharacter(double charSize) {
    final assetPath = BeeMascot.assetForState(widget.state);
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: charSize + 8,
        height: charSize + 8,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _bobController,
            _wingController,
            _tapBounceController,
          ]),
          builder: (context, child) {
            final bobY = math.sin(_bobController.value * math.pi) * 3.5 - 1.5;
            final breathScale = 1.0 +
                (_wingController.value - 0.5) *
                    (widget.state == MascotState.loader ? 0.04 : 0.02);
            final bounceScale = 1.0 +
                math.sin(_tapBounceController.value * math.pi) * 0.14;

            return Transform.translate(
              offset: Offset(0, bobY),
              child: Transform.scale(
                scale: breathScale * bounceScale,
                child: child,
              ),
            );
          },
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: Image.asset(
                assetPath,
                key: ValueKey<String>(assetPath),
                width: charSize,
                height: charSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeechBubble(
    BuildContext context,
    String text, {
    required bool compact,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSenior = widget.state == MascotState.seniorHelper;

    final bgColor = isSenior
        ? AppTheme.beelineYellow
        : (isDark ? const Color(0xFF1C1C22) : const Color(0xFFF3F3F7));
    final textColor = isSenior
        ? AppTheme.obsidianBlack
        : (isDark ? Colors.white : AppTheme.obsidianBlack);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 9 : 11,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        border: Border.all(
          color: isSenior
              ? Colors.transparent
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFE5E5EC)),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              text,
              key: ValueKey<String>(text),
              style: (compact
                      ? theme.textTheme.bodySmall
                      : (isSenior
                          ? theme.textTheme.titleMedium
                          : theme.textTheme.bodyMedium))
                  ?.copyWith(
                color: textColor,
                fontWeight: isSenior ? FontWeight.w800 : FontWeight.w600,
                height: 1.32,
              ),
            ),
          ),
          if (!compact && widget.cyclingMessages != null && widget.cyclingMessages!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                widget.language == AppLanguage.ru
                    ? 'Нажмите на пчёлку для совета'
                    : 'Кеңеш алуу үчүн аарыны басыңыз',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSenior
                      ? AppTheme.comicOutline.withValues(alpha: 0.75)
                      : AppTheme.beelineYellow,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
