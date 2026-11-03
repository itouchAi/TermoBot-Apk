import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sound_synthesis_service.dart';

enum MascotType {
  termobot,
  flamey,
  frosty,
}

enum MascotState {
  idle,
  walking,
  knocking,
  thinking,
  reading,
  lightSleep,
  deepSleep,
  happy,
  shivering, // < 19.5°C
  sweating,  // > 25.0°C
}

class UniversalMascot extends StatefulWidget {
  final MascotType type;
  final MascotState? forcedState;
  final double currentTemp;
  final double targetTemp;
  final bool isHeating;
  final double size;
  final bool interactive;
  final VoidCallback? onTap;

  const UniversalMascot({
    super.key,
    this.type = MascotType.termobot,
    this.forcedState,
    this.currentTemp = 21.8,
    this.targetTemp = 22.5,
    this.isHeating = false,
    this.size = 72.0,
    this.interactive = true,
    this.onTap,
  });

  @override
  State<UniversalMascot> createState() => _UniversalMascotState();
}

class _UniversalMascotState extends State<UniversalMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _stateTimer;
  Timer? _blinkTimer;

  MascotState _internalState = MascotState.idle;
  bool _isBlinking = false;
  String? _speechText;
  Timer? _speechTimer;

  MascotState get _effectiveState {
    if (widget.forcedState != null) return widget.forcedState!;

    // Sıcaklığa göre otonom reaksiyonlar
    if (widget.currentTemp < 19.2) {
      return MascotState.shivering;
    }
    if (widget.currentTemp > 25.0) {
      return MascotState.sweating;
    }
    return _internalState;
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _startBlinkLoop();
    _startAutonomousStateLoop();
  }

  @override
  void dispose() {
    _animController.dispose();
    _stateTimer?.cancel();
    _blinkTimer?.cancel();
    _speechTimer?.cancel();
    super.dispose();
  }

  void _startBlinkLoop() {
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 3200), (t) {
      if (!mounted) return;
      if (_effectiveState == MascotState.lightSleep ||
          _effectiveState == MascotState.deepSleep) return;

      setState(() => _isBlinking = true);
      Future.delayed(const Duration(milliseconds: 140), () {
        if (mounted) setState(() => _isBlinking = false);
      });
    });
  }

  void _startAutonomousStateLoop() {
    _stateTimer?.cancel();
    _stateTimer = Timer.periodic(const Duration(seconds: 7), (t) {
      if (!mounted) return;
      if (widget.forcedState != null) return;
      if (widget.currentTemp < 19.2 || widget.currentTemp > 25.0) return;

      final states = [
        MascotState.idle,
        MascotState.walking,
        MascotState.thinking,
        MascotState.knocking,
        MascotState.reading,
        MascotState.lightSleep,
      ];
      final nextIdx = (states.indexOf(_internalState) + 1) % states.length;
      final nextState = states[nextIdx];
      setState(() {
        _internalState = nextState;
      });

      if (nextState == MascotState.knocking) {
        SoundSynthesisService.playMascotSound(MascotSoundType.knock);
      } else if (nextState == MascotState.thinking) {
        SoundSynthesisService.playMascotSound(MascotSoundType.thinking);
      } else if (nextState == MascotState.lightSleep) {
        SoundSynthesisService.playMascotSound(MascotSoundType.sleep);
      }
    });
  }

  void _handleTap() {
    if (!widget.interactive) return;
    SoundSynthesisService.playMascotSound(MascotSoundType.happy);

    setState(() {
      _internalState = MascotState.happy;
    });

    // Maskota özel sevimli Türkçe replikler
    List<String> messages = [];
    if (widget.type == MascotType.termobot) {
      messages = [
        'TermoBot 24 saat nöbette! 🤖✨',
        'Oda şu an ${widget.currentTemp.toStringAsFixed(1)}°C 💛',
        widget.isHeating
            ? 'Kombi alevde, petekler ısınıyor! 🔥'
            : 'Tasarruf açık, hedef ${widget.targetTemp.toStringAsFixed(1)}°C ⚡',
      ];
    } else if (widget.type == MascotType.flamey) {
      messages = [
        'Alevim capcanlı! Ev sıcacık 🔥🧡',
        'Hedef sıcaklığa hızla ulaşıyoruz! 🚀',
        'Kombin modülasyonda, enerjin cepte kalsın! 💰',
      ];
    } else {
      messages = [
        'Hava soğuk ama evimiz sıcacık ❄️💙',
        'Buz gibi havalarda kombine güvenebilirsin! ☃️',
        'Titreme geçti, konfor derecesi harika! ✨',
      ];
    }

    final chosen = messages[math.Random().nextInt(messages.length)];
    setState(() => _speechText = chosen);

    _speechTimer?.cancel();
    _speechTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _speechText = null);
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _internalState == MascotState.happy) {
        setState(() => _internalState = MascotState.idle);
      }
    });

    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final state = _effectiveState;

    return GestureDetector(
      onTap: _handleTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── KONUŞMA VEYA DÜŞÜNCE BALONCUĞU ──
          if (_speechText != null)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: 1.0,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1A2C),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFF8C32).withOpacity(0.5)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: Text(
                  _speechText!,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else if (state == MascotState.thinking)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1928),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lightbulb_rounded, color: Color(0xFFFDE047), size: 14),
                  SizedBox(width: 4),
                  Text('Termal denge...', style: TextStyle(fontSize: 9.5, color: Colors.white70)),
                ],
              ),
            )
          else if (state == MascotState.lightSleep || state == MascotState.deepSleep)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              child: const Text('Z z z . . .', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFA855F7), fontFamily: 'monospace')),
            ),

          // ── MASKOT GPU GÖVDESİ & FİZİK ANİMASYONU ──
          AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              final t = _animController.value;

              // Hareket & Titreme Hesabı
              double dx = 0.0;
              double dy = math.sin(t * math.pi * 2) * 4.0;
              double rotate = 0.0;

              if (state == MascotState.shivering) {
                // Hızlı titreme
                dx = math.sin(t * 30.0) * 2.5;
                dy = math.cos(t * 30.0) * 1.5;
              } else if (state == MascotState.sweating) {
                // Yavaş nefes alma & bunalma
                dy = math.sin(t * math.pi * 2) * 2.0;
              } else if (state == MascotState.walking) {
                dx = math.sin(t * math.pi * 2) * 8.0;
                rotate = math.sin(t * math.pi * 2) * 0.08;
              } else if (state == MascotState.happy) {
                dy = -math.sin(t * math.pi * 4).abs() * 12.0;
                rotate = math.sin(t * math.pi * 4) * 0.12;
              }

              return Transform.translate(
                offset: Offset(dx, dy),
                child: Transform.rotate(
                  angle: rotate,
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _MascotCanvasPainter(
                      type: widget.type,
                      state: state,
                      isBlinking: _isBlinking,
                      isHeating: widget.isHeating,
                      animValue: t,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MascotCanvasPainter extends CustomPainter {
  final MascotType type;
  final MascotState state;
  final bool isBlinking;
  final bool isHeating;
  final double animValue;

  _MascotCanvasPainter({
    required this.type,
    required this.state,
    required this.isBlinking,
    required this.isHeating,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    switch (type) {
      case MascotType.termobot:
        _drawTermoBot(canvas, size, center);
        break;
      case MascotType.flamey:
        _drawFlamey(canvas, size, center);
        break;
      case MascotType.frosty:
        _drawFrosty(canvas, size, center);
        break;
    }
  }

  // 1. TERMOBOT: RETRO 3D ASİSTAN ROBOT
  void _drawTermoBot(Canvas canvas, Size size, Offset center) {
    final w = size.width;
    final h = size.height;

    // Alt Gölge
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.35);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, h - 4), width: w * 0.7, height: 8), shadowPaint);

    // Kafa & Gövde Şasisi (Retro Yuvarlak Kutu)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w * 0.85, height: h * 0.8),
      const Radius.circular(18),
    );

    final isCold = state == MascotState.shivering;
    final isHot = state == MascotState.sweating;

    Color bodyColor1 = const Color(0xFF282538);
    Color bodyColor2 = const Color(0xFF161424);

    if (isHeating) {
      bodyColor1 = const Color(0xFF3E2218);
      bodyColor2 = const Color(0xFF1F110B);
    } else if (isCold) {
      bodyColor1 = const Color(0xFF1A283C);
      bodyColor2 = const Color(0xFF0F1728);
    }

    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [bodyColor1, bodyColor2],
      ).createShader(bodyRect.outerRect);
    canvas.drawRRect(bodyRect, bodyPaint);

    // Dış Metalik Kenarlık
    final borderPaint = Paint()
      ..color = (isCold
          ? const Color(0xFF38BDF8)
          : isHeating
              ? const Color(0xFFFF8C32)
              : Colors.white.withOpacity(0.2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(bodyRect, borderPaint);

    // Tepe Anteni & Işık Küresi
    final antennaPath = Path()
      ..moveTo(center.dx, center.dy - (h * 0.4))
      ..lineTo(center.dx, center.dy - (h * 0.52));
    final antennaPaint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(antennaPath, antennaPaint);

    final tipColor = isHeating
        ? const Color(0xFFFF8C32)
        : isCold
            ? const Color(0xFF38BDF8)
            : const Color(0xFF10B981);
    final tipGlow = Paint()..color = tipColor.withOpacity(0.4);
    canvas.drawCircle(Offset(center.dx, center.dy - (h * 0.54)), 7, tipGlow);
    final tipPaint = Paint()..color = tipColor;
    canvas.drawCircle(Offset(center.dx, center.dy - (h * 0.54)), 4.5, tipPaint);

    // CRT Vizör Ekranı
    final visorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx, center.dy - (h * 0.08)), width: w * 0.65, height: h * 0.38),
      const Radius.circular(12),
    );
    final visorPaint = Paint()..color = const Color(0xFF0C0A14);
    canvas.drawRRect(visorRect, visorPaint);

    // Vizör Çerçevesi
    final visorBorder = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(visorRect, visorBorder);

    // Gözler (Canlı LED CRT Matrisi)
    final eyeY = center.dy - (h * 0.08);
    final eyeSpacing = w * 0.16;

    if (state == MascotState.lightSleep || state == MascotState.deepSleep) {
      // Uyku Gözleri (Çizgi şeklinde ^ ^)
      final sleepEye = Paint()
        ..color = const Color(0xFF38BDF8)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(center.dx - eyeSpacing - 5, eyeY), Offset(center.dx - eyeSpacing + 5, eyeY), sleepEye);
      canvas.drawLine(Offset(center.dx + eyeSpacing - 5, eyeY), Offset(center.dx + eyeSpacing + 5, eyeY), sleepEye);
    } else if (isBlinking) {
      // Göz Kırpma
      final blinkPaint = Paint()
        ..color = const Color(0xFF38BDF8)
        ..strokeWidth = 2.0;
      canvas.drawLine(Offset(center.dx - eyeSpacing - 6, eyeY), Offset(center.dx - eyeSpacing + 6, eyeY), blinkPaint);
      canvas.drawLine(Offset(center.dx + eyeSpacing - 6, eyeY), Offset(center.dx + eyeSpacing + 6, eyeY), blinkPaint);
    } else {
      // Normal Açık Parlayan LED Gözler
      Color eyeColor = const Color(0xFF38BDF8);
      if (isHeating || isHot) eyeColor = const Color(0xFFFFB800);
      if (state == MascotState.happy) eyeColor = const Color(0xFF10B981);

      final eyeGlow = Paint()..color = eyeColor.withOpacity(0.35);
      canvas.drawCircle(Offset(center.dx - eyeSpacing, eyeY), 7, eyeGlow);
      canvas.drawCircle(Offset(center.dx + eyeSpacing, eyeY), 7, eyeGlow);

      final eyePaint = Paint()..color = eyeColor;
      canvas.drawCircle(Offset(center.dx - eyeSpacing, eyeY), 4.5, eyePaint);
      canvas.drawCircle(Offset(center.dx + eyeSpacing, eyeY), 4.5, eyePaint);

      // Göz bebeği ışıltısı
      final pupilPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(center.dx - eyeSpacing - 1.5, eyeY - 1.5), 1.5, pupilPaint);
      canvas.drawCircle(Offset(center.dx + eyeSpacing - 1.5, eyeY - 1.5), 1.5, pupilPaint);
    }

    // Göğüs Termal Göstergesi (Alt Kısım)
    final chestY = center.dy + (h * 0.22);
    final chestRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx, chestY), width: w * 0.45, height: 10),
      const Radius.circular(5),
    );
    final chestBg = Paint()..color = Colors.black45;
    canvas.drawRRect(chestRect, chestBg);

    final ledCount = 4;
    for (int l = 0; l < ledCount; l++) {
      final lx = (center.dx - (w * 0.16)) + (l * (w * 0.1));
      Color ledColor = Colors.white24;
      if (isHeating && l < 3) ledColor = const Color(0xFFFF8C32);
      if (isCold && l == 0) ledColor = const Color(0xFF38BDF8);
      canvas.drawCircle(Offset(lx, chestY), 2.2, Paint()..color = ledColor);
    }
  }

  // 2. FLAMEY: ATEŞ & ALEV MASKOTU (SEVİMLİ SICAK KOMBİ DOSTU)
  void _drawFlamey(Canvas canvas, Size size, Offset center) {
    final w = size.width;
    final h = size.height;

    // Sıcak Amber Gölge
    final shadowPaint = Paint()..color = const Color(0xFFFF8C32).withOpacity(0.35);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, h - 4), width: w * 0.65, height: 8), shadowPaint);

    // Damla & Alev Gövdesi
    final flamePath = Path();
    flamePath.moveTo(center.dx, h * 0.12);
    // Üst alev kıvrımı
    flamePath.cubicTo(
      w * 0.85,
      h * 0.35,
      w * 0.95,
      h * 0.75,
      center.dx,
      h * 0.88,
    );
    flamePath.cubicTo(
      w * 0.05,
      h * 0.75,
      w * 0.15,
      h * 0.35,
      center.dx,
      h * 0.12,
    );

    final flamePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFDE047), Color(0xFFFF8C32), Color(0xFFDC2626)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(flamePath, flamePaint);

    // İç Çekirdek Alev (Daha Parlak Sarı)
    final innerPath = Path();
    innerPath.moveTo(center.dx, h * 0.35);
    innerPath.cubicTo(w * 0.75, h * 0.5, w * 0.8, h * 0.75, center.dx, h * 0.82);
    innerPath.cubicTo(w * 0.2, h * 0.75, w * 0.25, h * 0.5, center.dx, h * 0.35);
    final innerPaint = Paint()..color = const Color(0xFFFEF08A).withOpacity(0.85);
    canvas.drawPath(innerPath, innerPaint);

    // Gözler
    final eyeY = center.dy + 4;
    final eyeSpacing = w * 0.14;

    final eyePaint = Paint()..color = const Color(0xFF1E1005);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - eyeSpacing, eyeY), width: 7, height: 10), eyePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + eyeSpacing, eyeY), width: 7, height: 10), eyePaint);

    // Sevimli Yanak Pembeliği
    final cheekPaint = Paint()..color = const Color(0xFFEF4444).withOpacity(0.5);
    canvas.drawCircle(Offset(center.dx - eyeSpacing - 6, eyeY + 6), 4, cheekPaint);
    canvas.drawCircle(Offset(center.dx + eyeSpacing + 6, eyeY + 6), 4, cheekPaint);

    // Gülümseme Ağzı
    final mouthPath = Path();
    mouthPath.moveTo(center.dx - 6, eyeY + 8);
    mouthPath.quadraticBezierTo(center.dx, eyeY + 14, center.dx + 6, eyeY + 8);
    final mouthPaint = Paint()
      ..color = const Color(0xFF1E1005)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(mouthPath, mouthPaint);
  }

  // 3. FROSTY: BUZ & KAR KRİSTALİ MASKOTU
  void _drawFrosty(Canvas canvas, Size size, Offset center) {
    final w = size.width;
    final h = size.height;

    // Buzul Mavi Gölge
    final shadowPaint = Paint()..color = const Color(0xFF38BDF8).withOpacity(0.35);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, h - 4), width: w * 0.65, height: 8), shadowPaint);

    // Kristal Gövde (Yuvarlak Kar Topu)
    final bodyCenter = Offset(center.dx, center.dy + 4);
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF0F9FF), Color(0xFFBAE6FD), Color(0xFF38BDF8)],
      ).createShader(Rect.fromCircle(center: bodyCenter, radius: w * 0.4));
    canvas.drawCircle(bodyCenter, w * 0.38, bodyPaint);

    // Buz Boynuzları / Kristalleri
    final hornPaint = Paint()..color = const Color(0xFFE0F2FE);
    final leftHorn = Path()
      ..moveTo(center.dx - (w * 0.22), center.dy - (h * 0.25))
      ..lineTo(center.dx - (w * 0.36), center.dy - (h * 0.45))
      ..lineTo(center.dx - (w * 0.12), center.dy - (h * 0.32));
    canvas.drawPath(leftHorn, hornPaint);

    final rightHorn = Path()
      ..moveTo(center.dx + (w * 0.22), center.dy - (h * 0.25))
      ..lineTo(center.dx + (w * 0.36), center.dy - (h * 0.45))
      ..lineTo(center.dx + (w * 0.12), center.dy - (h * 0.32));
    canvas.drawPath(rightHorn, hornPaint);

    // Gözler (Koyu Mavi Kömür Gözler)
    final eyeY = center.dy + 2;
    final eyeSpacing = w * 0.13;
    final eyePaint = Paint()..color = const Color(0xFF0369A1);
    canvas.drawCircle(Offset(center.dx - eyeSpacing, eyeY), 4.5, eyePaint);
    canvas.drawCircle(Offset(center.dx + eyeSpacing, eyeY), 4.5, eyePaint);

    // Açık Mavi Yanaklar
    final cheekPaint = Paint()..color = const Color(0xFF38BDF8).withOpacity(0.4);
    canvas.drawCircle(Offset(center.dx - eyeSpacing - 5, eyeY + 6), 3.5, cheekPaint);
    canvas.drawCircle(Offset(center.dx + eyeSpacing + 5, eyeY + 6), 3.5, cheekPaint);

    // Gülümseme
    final mouthPath = Path();
    mouthPath.moveTo(center.dx - 5, eyeY + 8);
    mouthPath.quadraticBezierTo(center.dx, eyeY + 12, center.dx + 5, eyeY + 8);
    final mouthPaint = Paint()
      ..color = const Color(0xFF0369A1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(mouthPath, mouthPaint);
  }

  @override
  bool shouldRepaint(covariant _MascotCanvasPainter oldDelegate) => true;
}
