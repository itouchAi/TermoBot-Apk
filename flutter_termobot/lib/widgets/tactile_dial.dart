import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sound_synthesis_service.dart';

class TactileDialWidget extends StatefulWidget {
  final double currentTemp;
  final double targetTemp;
  final bool isHeating;
  final int flamePercent;
  final ValueChanged<double> onTargetChanged;

  const TactileDialWidget({
    super.key,
    required this.currentTemp,
    required this.targetTemp,
    required this.isHeating,
    required this.flamePercent,
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

    double angle = math.atan2(vector.dy, vector.dx);
    double degrees = angle * (180 / math.pi);
    if (degrees < 0) degrees += 360;

    double adjustedDeg = (degrees - 135);
    if (adjustedDeg < 0) adjustedDeg += 360;

    if (adjustedDeg <= 270) {
      double fraction = (adjustedDeg / 270).clamp(0.0, 1.0);
      double rawTemp = minTemp + fraction * (maxTemp - minTemp);
      double steppedTemp = (rawTemp * 2).round() / 2.0;

      if (steppedTemp != widget.targetTemp && steppedTemp >= minTemp && steppedTemp <= maxTemp) {
        SoundSynthesisService.playDialTick();
        widget.onTargetChanged(steppedTemp);
      }
    }
  }

  void _adjustDelta(double delta) {
    SoundSynthesisService.playDialTick();
    final next = (widget.targetTemp + delta).clamp(minTemp, maxTemp);
    final rounded = (next * 2).round() / 2.0;
    widget.onTargetChanged(rounded);
  }

  @override
  Widget build(BuildContext context) {
    const double dialSize = 290.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Kadran & Dokunmatik Yüzey
        GestureDetector(
          onPanUpdate: (details) => _handlePanUpdate(details, const Size(dialSize, dialSize)),
          child: SizedBox(
            width: dialSize,
            height: dialSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Arka plan derinlik gölgesi
                Container(
                  width: dialSize - 30,
                  height: dialSize - 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF131926),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),

                // GPU Canvas Çizimi
                CustomPaint(
                  size: const Size(dialSize, dialSize),
                  painter: _DialPainter(
                    currentTemp: widget.currentTemp,
                    targetTemp: widget.targetTemp,
                    isHeating: widget.isHeating,
                    flamePercent: widget.flamePercent,
                    minTemp: minTemp,
                    maxTemp: maxTemp,
                  ),
                ),

                // Merkezdeki LCD Ekran
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Isıtıyor / Beklemede Rozeti
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.isHeating
                            ? const Color(0xFFFF6A00).withOpacity(0.18)
                            : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.isHeating
                              ? const Color(0xFFFF6A00).withOpacity(0.5)
                              : Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.isHeating
                                ? '🔥 ISITIYOR (%${widget.flamePercent})'
                                : '❄️ BEKLEMEDE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: widget.isHeating
                                  ? const Color(0xFFFF6A00)
                                  : Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Hedef Sıcaklık Sayısı
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
                            color: Colors.white,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            '°C',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFF6A00),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Canlı Oda Sıcaklığı
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Oda: ${widget.currentTemp.toStringAsFixed(1)}°C',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 2. Hızlı -0.5 / +0.5 Stepper Düğmeleri
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepButton(
              icon: Icons.remove,
              label: '-0.5°',
              onTap: () => _adjustDelta(-0.5),
            ),
            const SizedBox(width: 20),
            _buildStepButton(
              icon: Icons.add,
              label: '+0.5°',
              onTap: () => _adjustDelta(0.5),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2638),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFFF6A00), size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double currentTemp;
  final double targetTemp;
  final bool isHeating;
  final int flamePercent;
  final double minTemp;
  final double maxTemp;

  _DialPainter({
    required this.currentTemp,
    required this.targetTemp,
    required this.isHeating,
    required this.flamePercent,
    required this.minTemp,
    required this.maxTemp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    const startAngle = 135 * (math.pi / 180);
    const totalSweep = 270 * (math.pi / 180);

    // 1. Arka plan izi
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

    // 2. Aktif Derece Yayı
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
            ? const [Color(0xFFFFAA00), Color(0xFFFF6A00), Color(0xFFFF3344)]
            : const [Color(0xFF00E5FF), Color(0xFFFFAA00)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      activeSweep,
      false,
      activePaint,
    );

    // 3. Döner Başparmak Düğmesi (Knob)
    final knobAngle = startAngle + activeSweep;
    final knobCenter = Offset(
      center.dx + radius * math.cos(knobAngle),
      center.dy + radius * math.sin(knobAngle),
    );

    // Işıma
    final glowPaint = Paint()
      ..color = (isHeating ? const Color(0xFFFF6A00) : const Color(0xFF00E5FF)).withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(knobCenter, 16, glowPaint);

    // Dış Halka
    final thumbOuterPaint = Paint()..color = Colors.white;
    canvas.drawCircle(knobCenter, 12, thumbOuterPaint);

    // İç Çekirdek
    final thumbInnerPaint = Paint()
      ..color = isHeating ? const Color(0xFFFF6A00) : const Color(0xFF00E5FF);
    canvas.drawCircle(knobCenter, 5, thumbInnerPaint);

    // 4. Çentik Çizgileri
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
        oldDelegate.isHeating != isHeating ||
        oldDelegate.flamePercent != flamePercent;
  }
}
