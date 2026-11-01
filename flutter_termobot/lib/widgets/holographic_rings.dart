import 'dart:math' as math;
import 'package:flutter/material.dart';

class HolographicRingsWidget extends StatefulWidget {
  final bool isHeating;
  final double flamePercent;
  final String activeTheme;

  const HolographicRingsWidget({
    super.key,
    required this.isHeating,
    required this.flamePercent,
    required this.activeTheme,
  });

  @override
  State<HolographicRingsWidget> createState() => _HolographicRingsWidgetState();
}

class _HolographicRingsWidgetState extends State<HolographicRingsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(320, 320),
          painter: _RingsPainter(
            progress: _controller.value,
            isHeating: widget.isHeating,
            flamePercent: widget.flamePercent,
            activeTheme: widget.activeTheme,
          ),
        );
      },
    );
  }
}

class _RingsPainter extends CustomPainter {
  final double progress;
  final bool isHeating;
  final double flamePercent;
  final String activeTheme;

  _RingsPainter({
    required this.progress,
    required this.isHeating,
    required this.flamePercent,
    required this.activeTheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2 - 25;

    // Renk Teması Belirleme
    Color primaryGlow;
    Color secondaryGlow;

    if (activeTheme == 'obsidian_lavender') {
      primaryGlow = const Color(0xFFB388FF);
      secondaryGlow = const Color(0xFF7C4DFF);
    } else if (activeTheme == 'cyber_glass') {
      primaryGlow = const Color(0xFF00E5FF);
      secondaryGlow = const Color(0xFF00B0FF);
    } else {
      // Tactile Deck (Kombiye göre Alev Kehribarı veya Derin Slate)
      primaryGlow = isHeating ? const Color(0xFFFF6A00) : const Color(0xFF475569);
      secondaryGlow = isHeating ? const Color(0xFFFFAA00) : const Color(0xFF334155);
    }

    // 1. Dış Nefes Alan Arka Plan Işıması
    final glowPaint = Paint()
      ..color = primaryGlow.withOpacity(isHeating ? 0.22 : 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 45);
    canvas.drawCircle(center, baseRadius + 15, glowPaint);

    // 2. 3D Çoklu Morfolojik Halka Katmanları
    for (int layer = 0; layer < 4; layer++) {
      final layerProgress = (progress + (layer * 0.25)) % 1.0;
      final angleOffset = layerProgress * 2 * math.pi;

      final ringPath = Path();
      const int segments = 60;
      final currentRadius = baseRadius - (layer * 16);

      for (int i = 0; i <= segments; i++) {
        final theta = (i / segments) * 2 * math.pi;
        // Morfolojik sinüs/kosinüs dalga deformasyonu (3D rotasyon hissi)
        final wave = math.sin(theta * 3 + angleOffset) * (isHeating ? 4.5 : 2.0);
        final r = currentRadius + wave;

        final x = center.dx + r * math.cos(theta);
        final y = center.dy + r * math.sin(theta);

        if (i == 0) {
          ringPath.moveTo(x, y);
        } else {
          ringPath.lineTo(x, y);
        }
      }
      ringPath.close();

      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = (layer % 2 == 0 ? primaryGlow : secondaryGlow)
            .withOpacity((0.35 - (layer * 0.07)).clamp(0.08, 0.45));

      canvas.drawPath(ringPath, ringPaint);
    }

    // 3. Yörüngede Dönen Enerji Parçacıkları
    final particlePaint = Paint()..style = PaintingStyle.fill;
    for (int p = 0; p < 8; p++) {
      final pAngle = (progress * 2 * math.pi) + (p * (math.pi / 4));
      final pRadius = baseRadius - 10 + math.sin(progress * 4 * math.pi + p) * 8;
      final px = center.dx + pRadius * math.cos(pAngle);
      final py = center.dy + pRadius * math.sin(pAngle);

      particlePaint.color = primaryGlow.withOpacity(0.5);
      canvas.drawCircle(Offset(px, py), 2.2, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isHeating != isHeating ||
        oldDelegate.flamePercent != flamePercent ||
        oldDelegate.activeTheme != activeTheme;
  }
}
