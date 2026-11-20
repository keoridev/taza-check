import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Crisp scalable vector brand logo for Kyrgyz telecom operators (`O!`, `Beeline`, `Mega`).
class OperatorLogo extends StatelessWidget {
  const OperatorLogo({
    super.key,
    required this.operatorName,
    this.size = 32,
  });

  final String operatorName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final normalized = operatorName.trim().toLowerCase();
    if (normalized == 'o!' || normalized == 'о!') {
      return _buildOLogo();
    }
    if (normalized.contains('beeline') || normalized.contains('билайн')) {
      return _buildBeelineLogo();
    }
    if (normalized.contains('mega')) {
      return _buildMegaLogo();
    }
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF26262C),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.sim_card_rounded,
        size: size * 0.54,
        color: Colors.white70,
      ),
    );
  }

  Widget _buildOLogo() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFEC008C),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size.square(size),
        painter: _OBrandPainter(),
      ),
    );
  }

  Widget _buildBeelineLogo() {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          size: Size.square(size),
          painter: _BeelineBrandPainter(),
        ),
      ),
    );
  }

  Widget _buildMegaLogo() {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          size: Size.square(size),
          painter: _MegaBrandPainter(),
        ),
      ),
    );
  }
}

class _OBrandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.14
      ..strokeCap = StrokeCap.round;

    // Stylized "O" ring shifted slightly left
    final oCenter = Offset(s * 0.42, s * 0.50);
    canvas.drawCircle(oCenter, s * 0.21, paint);

    // Exclamation mark "!" on the right
    final barPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.13
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(s * 0.74, s * 0.29),
      Offset(s * 0.74, s * 0.54),
      barPaint,
    );
    canvas.drawCircle(
      Offset(s * 0.74, s * 0.69),
      s * 0.068,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BeelineBrandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final yellow = Paint()..color = const Color(0xFFFFCC00);
    final black = Paint()..color = const Color(0xFF0D0D0F);

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), yellow);

    // 3 crisp horizontal black stripes
    final stripeH = h * 0.145;
    for (final yFrac in const [0.18, 0.43, 0.68]) {
      canvas.drawRect(Rect.fromLTWH(0, h * yFrac, w, stripeH), black);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MegaBrandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    // Deep purple circle fill
    canvas.drawRect(
      Rect.fromLTWH(0, 0, s, s),
      Paint()..color = const Color(0xFF5E239D),
    );

    // Vibrant lime-green accent arc on top-right
    final arcPaint = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.11
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(s / 2, s / 2), radius: s * 0.37),
      -math.pi * 0.45,
      math.pi * 0.65,
      false,
      arcPaint,
    );

    // Crisp geometric white "M" mark
    final mPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(s * 0.27, s * 0.68)
      ..lineTo(s * 0.27, s * 0.34)
      ..lineTo(s * 0.50, s * 0.55)
      ..lineTo(s * 0.73, s * 0.34)
      ..lineTo(s * 0.73, s * 0.68);
    canvas.drawPath(path, mPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
