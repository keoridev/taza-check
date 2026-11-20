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

  Color _accentForState() {
    return switch (widget.state) {
      MascotState.loader => AppTheme.beelineYellow,
      MascotState.alert => AppTheme.coralRed,
      MascotState.happy => AppTheme.electricGreen,
      MascotState.detective => AppTheme.beelineYellow,
      MascotState.seniorHelper => AppTheme.beelineYellow,
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
    final accent = _accentForState();
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: charSize + 18,
        height: charSize + 18,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _bobController,
            _wingController,
            _radarController,
            _tapBounceController,
          ]),
          builder: (context, child) {
            final bobY = math.sin(_bobController.value * math.pi) * 4.0 - 2.0;
            final flutterTilt =
                (_wingController.value - 0.5) *
                (widget.state == MascotState.loader ? 0.08 : 0.04);
            final bounceScale = 1.0 +
                math.sin(_tapBounceController.value * math.pi) * 0.14;

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // State-specific comic aura / radar ring
                if (widget.state == MascotState.loader)
                  Transform.rotate(
                    angle: _radarController.value * 2 * math.pi,
                    child: CustomPaint(
                      size: Size.square(charSize + 14),
                      painter: _RadarRingPainter(
                        accent: AppTheme.beelineYellow,
                        outline: AppTheme.comicOutline,
                      ),
                    ),
                  )
                else if (widget.state == MascotState.alert)
                  Container(
                    width: charSize + 8 + (_radarController.value * 8),
                    height: charSize + 8 + (_radarController.value * 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.coralRed.withValues(
                        alpha: 0.24 * (1.0 - _radarController.value * 0.6),
                      ),
                      border: Border.all(
                        color: AppTheme.coralRed.withValues(alpha: 0.55),
                        width: 2,
                      ),
                    ),
                  )
                else if (widget.state == MascotState.happy)
                  CustomPaint(
                    size: Size.square(charSize + 14),
                    painter: _SparkleAuraPainter(
                      progress: _radarController.value,
                    ),
                  )
                else if (widget.state == MascotState.seniorHelper)
                  Container(
                    width: charSize + 8,
                    height: charSize + 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.beelineYellow.withValues(alpha: 0.20),
                      border: Border.all(
                        color: AppTheme.beelineYellow,
                        width: 2.5,
                      ),
                    ),
                  ),

                // Mascot artwork with bobbing, wing flutter, and tap bounce
                Transform.translate(
                  offset: Offset(0, bobY),
                  child: Transform.rotate(
                    angle: flutterTilt,
                    child: Transform.scale(
                      scale: bounceScale,
                      child: child,
                    ),
                  ),
                ),

                // Expressive comic-outlined corner badge
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: _buildStateBadge(accent, charSize),
                ),
              ],
            );
          },
          child: Container(
            width: charSize,
            height: charSize,
            padding: EdgeInsets.all((charSize * 0.08).clamp(3.0, 7.0)),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.beelineYellow.withValues(alpha: 0.14),
              border: Border.all(
                color: AppTheme.beelineYellow.withValues(alpha: 0.38),
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/mascot/bee_base.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateBadge(Color accent, double charSize) {
    final badgeSize = (charSize * 0.34).clamp(18.0, 34.0);
    final iconSize = (badgeSize * 0.58).clamp(11.0, 20.0);

    final (IconData icon, Color bg, Color fg) = switch (widget.state) {
      MascotState.loader => (
          Icons.radar_rounded,
          AppTheme.beelineYellow,
          AppTheme.comicOutline,
        ),
      MascotState.alert => (
          Icons.gpp_maybe_rounded,
          AppTheme.coralRed,
          Colors.white,
        ),
      MascotState.happy => (
          Icons.verified_user_rounded,
          AppTheme.electricGreen,
          AppTheme.comicOutline,
        ),
      MascotState.detective => (
          Icons.search_rounded,
          AppTheme.beelineYellow,
          AppTheme.comicOutline,
        ),
      MascotState.seniorHelper => (
          Icons.favorite_rounded,
          AppTheme.beelineYellow,
          AppTheme.comicOutline,
        ),
    };

    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.comicOutline, width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            offset: Offset(1, 2),
            blurRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, size: iconSize, color: fg),
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
    final borderColor = switch (widget.state) {
      MascotState.alert => AppTheme.coralRed,
      MascotState.happy => AppTheme.electricGreen,
      _ => AppTheme.beelineYellow,
    };

    final bgColor = isSenior
        ? AppTheme.beelineYellow
        : (isDark ? AppTheme.carbonSurface : Colors.white);
    final textColor = isSenior
        ? AppTheme.comicOutline
        : (isDark ? Colors.white : AppTheme.obsidianBlack);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 8 : 11,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        border: Border.all(
          color: isSenior ? AppTheme.comicOutline : borderColor,
          width: isSenior ? 2.5 : 1.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
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

class _RadarRingPainter extends CustomPainter {
  const _RadarRingPainter({
    required this.accent,
    required this.outline,
  });

  final Color accent;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    final trackPaint = Paint()
      ..color = outline.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, radius, trackPaint);

    final arcPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi * 0.72,
      false,
      arcPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * 0.45,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarRingPainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.outline != outline;
}

class _SparkleAuraPainter extends CustomPainter {
  const _SparkleAuraPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final haloPaint = Paint()
      ..color = AppTheme.electricGreen.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 2, haloPaint);

    final starPaint = Paint()
      ..color = AppTheme.beelineYellow
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 4; i++) {
      final angle = progress * 2 * math.pi + i * (math.pi / 2);
      final dx = center.dx + math.cos(angle) * radius;
      final dy = center.dy + math.sin(angle) * radius;
      canvas.drawCircle(Offset(dx, dy), 3.2, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkleAuraPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
