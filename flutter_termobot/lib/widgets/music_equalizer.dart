import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/smart_display_config.dart';

class MusicEqualizer extends StatefulWidget {
  final bool enabled;
  final EqualizerStyle style;
  final bool isPlaying;

  const MusicEqualizer({
    super.key,
    required this.enabled,
    required this.style,
    required this.isPlaying,
  });

  @override
  State<MusicEqualizer> createState() => _MusicEqualizerState();
}

class _MusicEqualizerState extends State<MusicEqualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final int _bufferLength = 32;
  late List<double> _frequencies;
  late List<double> _peakBars;
  double _phase = 0.0;
  final math.Random _rnd = math.Random();

  @override
  void initState() {
    super.initState();
    _frequencies = List<double>.filled(_bufferLength, 0.0);
    _peakBars = List<double>.filled(_bufferLength, 0.0);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 32),
    )..addListener(_tick);

    if (widget.isPlaying) {
      _animController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant MusicEqualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_animController.isAnimating) {
      _animController.repeat();
    } else if (!widget.isPlaying && _animController.isAnimating) {
      _animController.stop();
      setState(() {
        _frequencies.fillRange(0, _bufferLength, 0.0);
      });
    }
  }

  void _tick() {
    if (!mounted) return;
    if (widget.isPlaying) {
      _phase += 0.05;
      for (int i = 0; i < _bufferLength; i++) {
        // Acoustic curve: simulate realistic frequency bands with harmonic oscillations
        final harmonic1 = math.sin(_phase * 2.2 + i * 0.45);
        final harmonic2 = math.cos(_phase * 1.5 - i * 0.28);
        final noise = _rnd.nextDouble() * 0.35;
        final bassBoost = i < 8 ? 0.35 : 0.0;
        final raw = ((harmonic1.abs() * 0.45) + (harmonic2.abs() * 0.3) + noise + bassBoost).clamp(0.0, 1.0);
        _frequencies[i] = raw;

        // Peak cap physics
        if (raw > _peakBars[i]) {
          _peakBars[i] = raw;
        } else {
          _peakBars[i] = math.max(0.0, _peakBars[i] - 0.035);
        }
      }
    } else {
      _frequencies.fillRange(0, _bufferLength, 0.0);
      for (int i = 0; i < _bufferLength; i++) {
        _peakBars[i] = math.max(0.0, _peakBars[i] - 0.05);
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();

    return SizedBox(
      width: 380,
      height: 72,
      child: CustomPaint(
        painter: _EqualizerPainter(
          style: widget.style,
          frequencies: _frequencies,
          peakBars: _peakBars,
          phase: _phase,
          isPlaying: widget.isPlaying,
        ),
      ),
    );
  }
}

class _EqualizerPainter extends CustomPainter {
  final EqualizerStyle style;
  final List<double> frequencies;
  final List<double> peakBars;
  final double phase;
  final bool isPlaying;

  _EqualizerPainter({
    required this.style,
    required this.frequencies,
    required this.peakBars,
    required this.phase,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case EqualizerStyle.bars:
        _paintNeonBars(canvas, size);
        break;
      case EqualizerStyle.wave:
        _paintSineWave(canvas, size);
        break;
      case EqualizerStyle.pulse:
        _paintRadialPulse(canvas, size);
        break;
    }
  }

  void _paintNeonBars(Canvas canvas, Size size) {
    final count = frequencies.length;
    final totalGap = (count - 1) * 3.0;
    final barWidth = math.max(3.0, (size.width - totalGap) / count);

    for (int i = 0; i < count; i++) {
      final freqBoost = 1.0 + (i / count) * 0.8;
      final val = (frequencies[i] * freqBoost).clamp(0.04, 1.0);
      final barHeight = math.max(4.0, val * (size.height * 0.88));
      final peakHeight = math.max(4.0, peakBars[i] * (size.height * 0.88));

      final x = i * (barWidth + 3.0);
      final y = size.height - barHeight;

      // Neon gradient: cyan -> purple -> rose
      final rect = Rect.fromLTWH(x, y, barWidth, barHeight);
      final paint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color(0x7038BDF8),
            Color(0xC0A855F7),
            Color(0xFFF43F5E),
          ],
        ).createShader(rect);

      final rrect = RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(2),
        topRight: const Radius.circular(2),
      );
      canvas.drawRRect(rrect, paint);

      // Peak cap line
      if (peakHeight > 6) {
        final capPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.95)
          ..style = PaintingStyle.fill;
        canvas.drawRect(
          Rect.fromLTWH(x, size.height - peakHeight - 2, barWidth, 2),
          capPaint,
        );
      }
    }
  }

  void _paintSineWave(Canvas canvas, Size size) {
    final centerY = size.height * 0.5;
    final wave1Path = Path()..moveTo(0, centerY);
    final wave2Path = Path()..moveTo(0, centerY);

    final step = 4.0;
    for (double x = 0; x <= size.width; x += step) {
      final normX = x / size.width;
      final index = (normX * (frequencies.length - 1)).clamp(0, frequencies.length - 1).toInt();
      final freqVal = frequencies[index];
      final amp = freqVal * (size.height * 0.42) + (isPlaying ? 4 : 0);

      final y1 = centerY +
          math.sin(normX * math.pi * 4.0 + phase) * amp +
          math.cos(normX * math.pi * 2.0 - phase * 0.7) * (amp * 0.5);
      wave1Path.lineTo(x, y1);

      final y2 = centerY +
          math.sin(normX * math.pi * 6.0 - phase * 1.2) * (amp * 0.7);
      wave2Path.lineTo(x, y2);
    }

    final wave1Paint = Paint()
      ..color = const Color(0xFFF43F5E).withValues(alpha: 0.92)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);
    canvas.drawPath(wave1Path, wave1Paint);

    final wave2Paint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.75)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(wave2Path, wave2Paint);
  }

  void _paintRadialPulse(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    double bassSum = 0.0;
    for (int b = 0; b < 6; b++) {
      bassSum += frequencies[b];
    }
    final bassVal = (bassSum / 6.0).clamp(0.0, 1.0);
    final maxRadius = (size.height * 0.44);
    final baseRadius = bassVal * maxRadius + 14.0;

    final rings = [
      (0.45, const Color(0xFFFB923C).withValues(alpha: 0.95), 2.8),
      (0.75, const Color(0xFFF43F5E).withValues(alpha: 0.65), 2.2),
      (1.00, const Color(0xFFA855F7).withValues(alpha: 0.40), 1.6),
    ];

    for (final ring in rings) {
      final r = baseRadius * ring.$1;
      final paint = Paint()
        ..color = ring.$2
        ..strokeWidth = ring.$3
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EqualizerPainter oldDelegate) => true;
}
