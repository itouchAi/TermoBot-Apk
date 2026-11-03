import 'dart:math' as math;
import 'package:flutter/material.dart';

class ComfortIndexResult {
  final int score;
  final String label;
  final Color color;
  final String advice;

  const ComfortIndexResult({
    required this.score,
    required this.label,
    required this.color,
    required this.advice,
  });
}

ComfortIndexResult calculateComfortIndex(double temp, double humidity) {
  double score = 100.0;
  final tempDiff = (temp - 22.0).abs();
  score -= tempDiff * 15.0;

  final humDiff = (humidity - 50.0).abs();
  score -= humDiff * 0.8;

  final clamped = score.clamp(10.0, 100.0).round();

  if (clamped >= 85) {
    return ComfortIndexResult(
      score: clamped,
      label: 'Mükemmel Konfor',
      color: const Color(0xFF10B981),
      advice: 'Sıcaklık ve nem oranları ideal sağlık & tasarruf bandında.',
    );
  } else if (clamped >= 65) {
    return ComfortIndexResult(
      score: clamped,
      label: 'İyi / Dengeli',
      color: const Color(0xFF38BDF8),
      advice: 'Hafif sıcaklık dalgalanması mevcut, oda dengeleniyor.',
    );
  } else if (clamped >= 45) {
    return ComfortIndexResult(
      score: clamped,
      label: 'Orta Seviye',
      color: const Color(0xFFF59E0B),
      advice: 'Hava kuruluğu veya sıcaklık farkı var, havalandırma önerilir.',
    );
  } else {
    return ComfortIndexResult(
      score: clamped,
      label: 'Düşük Konfor',
      color: const Color(0xFFEF4444),
      advice: 'Sıcaklık konfor eşiğinin dışında. Termostat hedefini kontrol edin.',
    );
  }
}

class ComfortIndexWidget extends StatelessWidget {
  final double currentTemp;
  final double humidity;

  const ComfortIndexWidget({
    super.key,
    required this.currentTemp,
    required this.humidity,
  });

  @override
  Widget build(BuildContext context) {
    final res = calculateComfortIndex(currentTemp, humidity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1828),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: const [
          BoxShadow(color: Color(0xFF0C0B10), offset: Offset(0, 4), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          // Dairesel Konfor Yüzdesi Göstergesi
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(70, 70),
                  painter: _RadialScorePainter(score: res.score, color: res.color),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '%${res.score}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: res.color,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const Text('KONFOR', style: TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Sağ Bilgi ve Tavsiye Alanı
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      res.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: res.color,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: res.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Nem: %${humidity.toInt()}',
                        style: TextStyle(fontSize: 10, color: res.color, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  res.advice,
                  style: const TextStyle(fontSize: 10.5, color: Colors.white70, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RadialScorePainter extends CustomPainter {
  final int score;
  final Color color;

  _RadialScorePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Arka plan çemberi
    final bgPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, radius, bgPaint);

    // İlerleme yayı
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6;

    final sweepAngle = (score / 100.0) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
