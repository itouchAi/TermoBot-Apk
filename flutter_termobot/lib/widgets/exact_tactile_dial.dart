import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sound_synthesis_service.dart';

class ExactTactileDial extends StatefulWidget {
  final double targetTemp;
  final double currentTemp;
  final bool isHeating;
  final String activeModeName;
  final ValueChanged<double> onSetTarget;

  const ExactTactileDial({
    super.key,
    required this.targetTemp,
    required this.currentTemp,
    required this.isHeating,
    required this.activeModeName,
    required this.onSetTarget,
  });

  @override
  State<ExactTactileDial> createState() => _ExactTactileDialState();
}

class _ExactTactileDialState extends State<ExactTactileDial> {
  static const double minTemp = 16.0;
  static const double maxTemp = 30.0;
  bool _isDragging = false;

  void _updateAngleFromLocalPos(Offset pos, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = pos.dx - center.dx;
    final dy = pos.dy - center.dy;

    // Angle in degrees where 12 o'clock is 0, clockwise positive (-180 to +180)
    double deg = (math.atan2(dy, dx) * 180 / math.pi) + 90;
    while (deg > 180) deg -= 360;
    while (deg < -180) deg += 360;

    // Guard against flipping through bottom gap (-135° to +135°)
    double targetAngle = deg;
    if (targetAngle > 135) targetAngle = 135;
    if (targetAngle < -135) targetAngle = -135;

    final fraction = (targetAngle - (-135)) / 270;
    final rawTemp = minTemp + fraction * (maxTemp - minTemp);
    final stepped = (rawTemp * 2).round() / 2.0;
    final clamped = stepped.clamp(minTemp, maxTemp);

    if (clamped != widget.targetTemp) {
      SoundSynthesisService.playDialTick();
      widget.onSetTarget(clamped);
    }
  }

  void _adjustStep(double delta) {
    SoundSynthesisService.playDialTick();
    final next = (widget.targetTemp + delta).clamp(minTemp, maxTemp);
    widget.onSetTarget((next * 2).round() / 2.0);
  }

  @override
  Widget build(BuildContext context) {
    const double dialDiameter = 240.0;
    // Map targetTemp (16.0 to 30.0) to angle (-135° to +135°)
    final currentAngleDeg = ((widget.targetTemp - minTemp) / (maxTemp - minTemp)) * 270 - 135;

    // Mode badge color
    Color badgeColor = const Color(0xFFF59E0B); // Amber
    if (widget.activeModeName.contains('EKO')) {
      badgeColor = const Color(0xFF10B981);
    } else if (widget.activeModeName.contains('GECE')) {
      badgeColor = const Color(0xFF818CF8);
    } else if (widget.activeModeName.contains('BOOST')) {
      badgeColor = const Color(0xFFFB923C);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── DÖNER MEKANİK KADRAN (Exact 3D Knurled Rotary Dial) ──
        GestureDetector(
          onPanStart: (details) {
            setState(() => _isDragging = true);
            _updateAngleFromLocalPos(details.localPosition, const Size(dialDiameter, dialDiameter));
          },
          onPanUpdate: (details) {
            _updateAngleFromLocalPos(details.localPosition, const Size(dialDiameter, dialDiameter));
          },
          onPanEnd: (_) => setState(() => _isDragging = false),
          onPanCancel: () => setState(() => _isDragging = false),
          child: Container(
            width: dialDiameter,
            height: dialDiameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                const BoxShadow(
                  color: Color(0xCC000000),
                  blurRadius: 30,
                  offset: Offset(0, 16),
                ),
                BoxShadow(
                  color: const Color(0xFFFF8C3C).withOpacity(
                    _isDragging ? 0.65 : (widget.isHeating ? 0.45 : 0.12),
                  ),
                  blurRadius: _isDragging ? 45 : (widget.isHeating ? 30 : 15),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Dış Tırtıklı Dişli Halka (Knurled Gear Teeth)
                CustomPaint(
                  size: const Size(dialDiameter, dialDiameter),
                  painter: _KnurledGearPainter(),
                ),

                // 2. İç Metalik Bombeli Kubbe (Inner Convex Dome)
                Container(
                  width: dialDiameter - 34,
                  height: dialDiameter - 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(-0.35, -0.45),
                      radius: 0.85,
                      colors: [
                        Color(0xFF4C4954),
                        Color(0xFF282530),
                        Color(0xFF141318),
                      ],
                      stops: [0.0, 0.45, 1.0],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.22),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.25),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.85),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Dönen Turuncu Işık Barı (Rotating Indicator Pill)
                      Transform.rotate(
                        angle: currentAngleDeg * math.pi / 180,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            margin: const EdgeInsets.only(top: 8),
                            width: 8,
                            height: 18,
                            decoration: BoxDecoration(
                              color: _isDragging
                                  ? const Color(0xFFFFBE76)
                                  : (widget.isHeating ? const Color(0xFFFF9A4A) : const Color(0xFFF59E0B)),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF7A1A).withOpacity(0.9),
                                  blurRadius: _isDragging ? 20 : 12,
                                  spreadRadius: 2,
                                ),
                                const BoxShadow(
                                  color: Colors.white,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Merkezdeki Tipografi (HEDEF TERMOSTAT, 21.5°, MANUEL MODU)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'HEDEF TERMOSTAT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                              color: Color(0xFF8F9BB3),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.targetTemp.toStringAsFixed(1)}°',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              letterSpacing: -2,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black87,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.activeModeName} MODU',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: badgeColor,
                              shadows: [
                                Shadow(
                                  color: badgeColor.withOpacity(0.6),
                                  blurRadius: 10,
                                ),
                              ],
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
        ),

        const SizedBox(height: 16),

        // ── [-] ±0.5°C [+] 3D BOMBELİ STEPPER DÜĞMELERİ ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _build3DStepButton(
              label: '-',
              onTap: () => _adjustStep(-0.5),
            ),
            const SizedBox(width: 14),
            const Text(
              '±0.5°C',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
                color: Color(0xFFCBD5E1),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 14),
            _build3DStepButton(
              label: '+',
              onTap: () => _adjustStep(0.5),
            ),
          ],
        ),
      ],
    );
  }

  Widget _build3DStepButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(0.0, -0.2),
            radius: 0.75,
            colors: [Color(0xFF464250), Color(0xFF201E27)],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.22),
            width: 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF0C0B10),
              offset: Offset(0, 5),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Colors.black54,
              offset: Offset(0, 10),
              blurRadius: 14,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _KnurledGearPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    const int totalTeeth = 64;
    final teethPaintDark = Paint()
      ..color = const Color(0xFF0B0A0F)
      ..style = PaintingStyle.fill;

    final teethPaintLight = Paint()
      ..color = const Color(0xFF5D5663)
      ..style = PaintingStyle.fill;

    // Conic repeating notched gear teeth
    for (int i = 0; i < totalTeeth; i++) {
      final startAngle = (i / totalTeeth) * 2 * math.pi;
      final sweepAngle = (1 / totalTeeth) * 2 * math.pi;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        i % 2 == 0 ? teethPaintDark : teethPaintLight,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
