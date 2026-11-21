import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

/// Smoothly animates monetary amounts (in KGS) using `TweenAnimationBuilder`
/// while preserving exact `Decimal` target formatting.
class AnimatedSomText extends StatelessWidget {
  const AnimatedSomText({
    super.key,
    required this.amount,
    this.prefix = '',
    this.suffix = ' сом',
    this.style,
    this.maxLines = 1,
    this.duration = const Duration(milliseconds: 350),
  });

  final Decimal amount;
  final String prefix;
  final String suffix;
  final TextStyle? style;
  final int maxLines;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final target = amount.toDouble();
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: target, end: target),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final formatted = value.toStringAsFixed(2);
        return Text(
          '$prefix$formatted$suffix',
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: style,
        );
      },
    );
  }
}
