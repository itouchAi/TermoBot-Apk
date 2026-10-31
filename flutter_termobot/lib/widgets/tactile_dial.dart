import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class TactileDialWidget extends StatefulWidget {
  final double currentTemp;
  final double targetTemp;
  final bool isHeating;
  final ValueChanged<double> onTargetChanged;

  const TactileDialWidget({
    super.key,
    required this.currentTemp,
    required this.targetTemp,
    required this.isHeating,
    required this.onTargetChanged,
  });

  @override
  State<TactileDialWidget> createState() => _TactileDialWidgetState();
}

class _TactileDialWidgetState extends State<TactileDialWidget> {
  static const double minTemp = 10.0;
  static const double maxTemp = 35.0;

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final touchPosition = details.localPosition;
    final vector = touchPosition - center;

    // Angle in radians (-pi to pi)
    double angle = math.atan2(vector.dy, vector.dx);
    // Convert so bottom is 0: angle relative to 135 deg (3*pi/4)
    // Dial sweep is from 135 deg to 405 deg (270 degree total arc)
    double degrees = angle * (180 / math.pi);
    if (degrees < 0) degrees += 360;

    // Shift zero to 135 deg (bottom left)
    double adjustedDeg = (degrees - 135);
    if (adjustedDeg < 0) adjustedDeg += 360;

    if (adjustedDeg <= 270) {
      double fraction = (adjustedDeg / 270).clamp(0.0, 1.0);
      double rawTemp = minTemp + fraction * (maxTemp - minTemp);
      double steppedTemp = (rawTemp * 2).round() / 2.0;

      if (steppedTemp != widget.targetTemp && steppedTemp >= minTemp && steppedTemp <= maxTemp) {
        HapticFeedback.selectionClick();
        widget.onTargetChanged(steppedTemp);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double dialSize = 280.0;

    return Center(
      child: GestureDetector(
        onPanUpdate: (details) => _handlePanUpdate(details, const Size(dialSize, dialSize)),
        child: SizedBox(
          width: dialSize,
          height: dialSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // GPU CustomPainter Arc & Ticks
              CustomPaint(
                size: const Size(dialSize, dialSize),
                painter: _DialPainter(
                  currentTemp: widget.currentTemp,
                  targetTemp: widget.targetTemp,
                  isHeating: widget.isHeating,
                  minTemp: minTemp,
                  maxTemp: maxTemp,
                ),
              ),

              // Central Info Display (Target Temp, Status, Difference)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // State badge (Isıtıyor / Beklemede)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: widget.isHeating
                          ? AppTheme.flameOrange.withOpacity(0.18)
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.isHeating
                            ? AppTheme.flameOrange.withOpacity(0.5)
                            : Colors.white.withOpacity(0.12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.isHeating ? '🔥 ISITIYOR' : '❄️ BEKLEMEDE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: widget.isHeating ? AppTheme.flameOrange : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Large Target Temp with degree symbol
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.targetTemp.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          '°C',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.flameOrange,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Current Oda Temp indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Oda: ${widget.currentTemp.toStringAsFixed(1)}°C',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double currentTemp;
  final double targetTemp;
  final bool isHeating;
  final double minTemp;
  final double maxTemp;

  _DialPainter({
    required this.currentTemp,
    required this.targetTemp,
    required this.isHeating,
    required this.minTemp,
    required this.maxTemp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Sweep arc is 270 degrees, starting at 135 degrees (3 * pi / 4)
    const startAngle = 135 * (math.pi / 180);
    const totalSweep = 270 * (math.pi / 180);

    // 1. Background Track
    final trackPaint = Paint()
      ..color = const Color(0xFF1B2436)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalSweep,
      false,
      trackPaint,
    );

    // 2. Target Temperature Active Arc
    final targetFraction = ((targetTemp - minTemp) / (maxTemp - minTemp)).clamp(0.0, 1.0);
    final activeSweep = totalSweep * targetFraction;

    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + totalSweep,
        colors: isHeating
            ? [AppTheme.flameAmber, AppTheme.flameOrange, AppTheme.flameRed]
            : [AppTheme.cyanCool, AppTheme.flameAmber],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      activeSweep,
      false,
      activePaint,
    );

    // 3. Thumb Knob at current target angle
    final knobAngle = startAngle + activeSweep;
    final knobCenter = Offset(
      center.dx + radius * math.cos(knobAngle),
      center.dy + radius * math.sin(knobAngle),
    );

    // Glow shadow
    final glowPaint = Paint()
      ..color = (isHeating ? AppTheme.flameOrange : AppTheme.cyanCool).withOpacity(0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(knobCenter, 14, glowPaint);

    // Outer thumb
    final thumbOuterPaint = Paint()..color = Colors.white;
    canvas.drawCircle(knobCenter, 11, thumbOuterPaint);

    // Inner thumb dot
    final thumbInnerPaint = Paint()
      ..color = isHeating ? AppTheme.flameOrange : AppTheme.cyanCool;
    canvas.drawCircle(knobCenter, 5, thumbInnerPaint);

    // 4. Subtle Tick Marks around arc
    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 1.5;

    for (int i = 0; i <= 25; i++) {
      final tickAngle = startAngle + (totalSweep * (i / 25));
      final innerTick = Offset(
        center.dx + (radius - 18) * math.cos(tickAngle),
        center.dy + (radius - 18) * math.sin(tickAngle),
      );
      final outerTick = Offset(
        center.dx + (radius - 12) * math.cos(tickAngle),
        center.dy + (radius - 12) * math.sin(tickAngle),
      );
      canvas.drawLine(innerTick, outerTick, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) {
    return oldDelegate.targetTemp != targetTemp ||
        oldDelegate.currentTemp != currentTemp ||
        oldDelegate.isHeating != isHeating;
  }
}
