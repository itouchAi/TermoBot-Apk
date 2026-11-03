import 'dart:math' as math;
import 'package:flutter/material.dart';

enum WeatherType {
  sunny,
  partlyCloudy,
  cloudy,
  rainy,
  thunder,
  snowy,
  fog,
}

class WeatherParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double alpha;
  double length;
  double phase;
  Color color;

  WeatherParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.alpha,
    this.length = 0,
    this.phase = 0,
    required this.color,
  });
}

class SplashParticle {
  double x;
  double y;
  double vx;
  double vy;
  double alpha;
  double radius;

  SplashParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.alpha,
    required this.radius,
  });
}

class VolumetricCloud {
  double x;
  double y;
  double speed;
  double scale;
  List<Offset> puffOffsets;
  List<double> puffRadii;

  VolumetricCloud({
    required this.x,
    required this.y,
    required this.speed,
    required this.scale,
    required this.puffOffsets,
    required this.puffRadii,
  });
}

class AtmosphericWeatherCanvas extends StatefulWidget {
  final WeatherType weatherType;
  final bool isNight;
  final Widget? child;

  const AtmosphericWeatherCanvas({
    super.key,
    this.weatherType = WeatherType.partlyCloudy,
    this.isNight = false,
    this.child,
  });

  @override
  State<AtmosphericWeatherCanvas> createState() => _AtmosphericWeatherCanvasState();
}

class _AtmosphericWeatherCanvasState extends State<AtmosphericWeatherCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<WeatherParticle> _particles = [];
  final List<SplashParticle> _splashes = [];
  final List<VolumetricCloud> _clouds = [];

  double _lightningOpacity = 0.0;
  List<Offset> _lightningBolts = [];
  math.Random random = math.Random();
  Size _lastSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _controller.addListener(_updatePhysics);
  }

  @override
  void didUpdateWidget(AtmosphericWeatherCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weatherType != widget.weatherType ||
        oldWidget.isNight != widget.isNight) {
      if (_lastSize != Size.zero) {
        _initSystem(_lastSize);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initSystem(Size size) {
    _particles.clear();
    _splashes.clear();
    _clouds.clear();
    _lastSize = size;

    final w = size.width;
    final h = size.height;

    // 1. Yıldızlar (Gece Açık & Parçalı Bulutlu ise)
    if (widget.isNight) {
      final starCount = widget.weatherType == WeatherType.sunny ||
              widget.weatherType == WeatherType.partlyCloudy
          ? 70
          : 30;
      for (int i = 0; i < starCount; i++) {
        _particles.add(
          WeatherParticle(
            x: random.nextDouble() * w,
            y: random.nextDouble() * (h * 0.7),
            vx: 0,
            vy: 0,
            size: 0.8 + random.nextDouble() * 2.0,
            alpha: 0.4 + random.nextDouble() * 0.6,
            phase: random.nextDouble() * math.pi * 2,
            color: random.nextBool()
                ? Colors.white
                : (random.nextBool()
                    ? const Color(0xFFBAE6FD)
                    : const Color(0xFFFEF08A)),
          ),
        );
      }
    }

    // 2. Yağmur Damlaları (Rainy & Thunder)
    if (widget.weatherType == WeatherType.rainy ||
        widget.weatherType == WeatherType.thunder) {
      final dropCount = widget.weatherType == WeatherType.thunder ? 95 : 75;
      for (int i = 0; i < dropCount; i++) {
        _particles.add(
          WeatherParticle(
            x: random.nextDouble() * (w + 160) - 80,
            y: random.nextDouble() * h,
            vx: -2.5 - random.nextDouble() * 2.0,
            vy: 14.0 + random.nextDouble() * 10.0,
            length: 18.0 + random.nextDouble() * 16.0,
            size: 1.2 + random.nextDouble() * 1.0,
            alpha: 0.4 + random.nextDouble() * 0.5,
            color: const Color(0xFFBAE6FD),
          ),
        );
      }
    }

    // 3. Kar Taneleri (Snowy)
    if (widget.weatherType == WeatherType.snowy) {
      for (int i = 0; i < 65; i++) {
        _particles.add(
          WeatherParticle(
            x: random.nextDouble() * w,
            y: random.nextDouble() * h,
            vx: (random.nextDouble() - 0.5) * 1.2,
            vy: 1.0 + random.nextDouble() * 2.2,
            size: 2.0 + random.nextDouble() * 3.5,
            alpha: 0.5 + random.nextDouble() * 0.5,
            phase: random.nextDouble() * math.pi * 2,
            color: Colors.white,
          ),
        );
      }
    }

    // 4. Hacimsel Puf Bulutlar
    int cloudCount = 0;
    if (widget.weatherType == WeatherType.partlyCloudy) cloudCount = 4;
    if (widget.weatherType == WeatherType.cloudy) cloudCount = 6;
    if (widget.weatherType == WeatherType.rainy ||
        widget.weatherType == WeatherType.thunder) cloudCount = 7;
    if (widget.weatherType == WeatherType.fog) cloudCount = 5;

    for (int c = 0; c < cloudCount; c++) {
      final puffCount = 6 + random.nextInt(4);
      final List<Offset> offsets = [];
      final List<double> radii = [];

      for (int p = 0; p < puffCount; p++) {
        offsets.add(Offset(
          (p - (puffCount / 2)) * 32.0 + (random.nextDouble() * 20 - 10),
          (random.nextDouble() * 18 - 9),
        ));
        radii.add(28.0 + random.nextDouble() * 22.0);
      }

      _clouds.add(
        VolumetricCloud(
          x: (c * (w / cloudCount)) + (random.nextDouble() * 60 - 30),
          y: (h * 0.05) + random.nextDouble() * (h * 0.35),
          speed: 0.35 + random.nextDouble() * 0.45,
          scale: 0.8 + random.nextDouble() * 0.5,
          puffOffsets: offsets,
          puffRadii: radii,
        ),
      );
    }
  }

  void _updatePhysics() {
    if (_lastSize == Size.zero) return;
    final w = _lastSize.width;
    final h = _lastSize.height;

    // Bulut hareketi
    for (var cloud in _clouds) {
      cloud.x += cloud.speed;
      if (cloud.x - 160 > w) {
        cloud.x = -160;
        cloud.y = (h * 0.05) + random.nextDouble() * (h * 0.35);
      }
    }

    // Parçacık simülasyonu
    for (var p in _particles) {
      if (widget.weatherType == WeatherType.rainy ||
          widget.weatherType == WeatherType.thunder) {
        p.x += p.vx;
        p.y += p.vy;

        // Yere çarptığında sıçrama üret
        if (p.y >= h - 10) {
          if (random.nextDouble() > 0.65 && _splashes.length < 35) {
            _splashes.add(
              SplashParticle(
                x: p.x,
                y: h - 6,
                vx: (random.nextDouble() - 0.5) * 4.0,
                vy: -1.5 - random.nextDouble() * 3.0,
                alpha: 0.8,
                radius: 1.2 + random.nextDouble() * 1.5,
              ),
            );
          }
          p.y = -p.length;
          p.x = random.nextDouble() * (w + 160) - 80;
        }
      } else if (widget.weatherType == WeatherType.snowy) {
        p.phase += 0.03;
        p.x += p.vx + math.sin(p.phase) * 0.8;
        p.y += p.vy;

        if (p.y > h) {
          p.y = -10;
          p.x = random.nextDouble() * w;
        }
      } else if (widget.isNight) {
        // Yıldız parıldaması
        p.phase += 0.05;
        p.alpha = 0.35 + (math.sin(p.phase).abs() * 0.55);
      }
    }

    // Sıçrama damlaları güncelleme
    for (int s = _splashes.length - 1; s >= 0; s--) {
      final sp = _splashes[s];
      sp.x += sp.vx;
      sp.y += sp.vy;
      sp.vy += 0.3; // yerçekimi
      sp.alpha -= 0.05;
      if (sp.alpha <= 0) {
        _splashes.removeAt(s);
      }
    }

    // Şimşek kontrolü (Thunder)
    if (widget.weatherType == WeatherType.thunder) {
      if (_lightningOpacity > 0.05) {
        _lightningOpacity *= 0.82;
      } else {
        _lightningOpacity = 0.0;
        _lightningBolts.clear();
      }

      // Rastgele şimşek tetikleme
      if (random.nextDouble() < 0.008 && _lightningOpacity == 0.0) {
        _lightningOpacity = 0.85 + random.nextDouble() * 0.15;
        _generateLightningBolts(w, h);
      }
    }
  }

  void _generateLightningBolts(double w, double h) {
    _lightningBolts.clear();
    double startX = w * 0.2 + random.nextDouble() * (w * 0.6);
    double startY = 10.0;
    _lightningBolts.add(Offset(startX, startY));

    double curX = startX;
    double curY = startY;

    while (curY < h * 0.65) {
      curY += 20 + random.nextDouble() * 30;
      curX += (random.nextDouble() - 0.5) * 45;
      _lightningBolts.add(Offset(curX, curY));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final currentSize = Size(constraints.maxWidth, constraints.maxHeight);
        if (_lastSize != currentSize && currentSize.width > 0) {
          _initSystem(currentSize);
        }

        return Stack(
          children: [
            // GPU CustomPaint Arka Planı
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  size: currentSize,
                  painter: _AtmosphericCanvasPainter(
                    weatherType: widget.weatherType,
                    isNight: widget.isNight,
                    particles: _particles,
                    splashes: _splashes,
                    clouds: _clouds,
                    lightningOpacity: _lightningOpacity,
                    lightningBolts: _lightningBolts,
                  ),
                );
              },
            ),

            // Üstündeki içerik
            if (widget.child != null) widget.child!,
          ],
        );
      },
    );
  }
}

class _AtmosphericCanvasPainter extends CustomPainter {
  final WeatherType weatherType;
  final bool isNight;
  final List<WeatherParticle> particles;
  final List<SplashParticle> splashes;
  final List<VolumetricCloud> clouds;
  final double lightningOpacity;
  final List<Offset> lightningBolts;

  _AtmosphericCanvasPainter({
    required this.weatherType,
    required this.isNight,
    required this.particles,
    required this.splashes,
    required this.clouds,
    required this.lightningOpacity,
    required this.lightningBolts,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // ── 1. GÖKYÜZÜ GRADYANI ──
    late List<Color> skyColors;
    if (isNight) {
      skyColors = const [
        Color(0xFF040714),
        Color(0xFF0C1327),
        Color(0xFF141A30),
      ];
    } else {
      switch (weatherType) {
        case WeatherType.sunny:
          skyColors = const [
            Color(0xFF0284C7),
            Color(0xFF38BDF8),
            Color(0xFFBAE6FD),
          ];
          break;
        case WeatherType.partlyCloudy:
          skyColors = const [
            Color(0xFF0369A1),
            Color(0xFF0EA5E9),
            Color(0xFF93C5FD),
          ];
          break;
        case WeatherType.cloudy:
          skyColors = const [
            Color(0xFF1E293B),
            Color(0xFF334155),
            Color(0xFF475569),
          ];
          break;
        case WeatherType.rainy:
          skyColors = const [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF334155),
          ];
          break;
        case WeatherType.thunder:
          skyColors = const [
            Color(0xFF090D1A),
            Color(0xFF141C2E),
            Color(0xFF1E293B),
          ];
          break;
        case WeatherType.snowy:
          skyColors = const [
            Color(0xFF1E293B),
            Color(0xFF475569),
            Color(0xFF94A3B8),
          ];
          break;
        case WeatherType.fog:
          skyColors = const [
            Color(0xFF334155),
            Color(0xFF64748B),
            Color(0xFF94A3B8),
          ];
          break;
      }
    }

    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: skyColors,
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // ── 2. GÖK CİSMİ (GÜNEŞ VEYA AY) ──
    if (!isNight &&
        (weatherType == WeatherType.sunny ||
            weatherType == WeatherType.partlyCloudy)) {
      // Parlayan Güneş & Korona
      final sunCenter = Offset(size.width * 0.8, size.height * 0.16);
      final coronaPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFDE047).withOpacity(0.5),
            const Color(0xFFF59E0B).withOpacity(0.15),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: sunCenter, radius: 55));
      canvas.drawCircle(sunCenter, 55, coronaPaint);

      final sunPaint = Paint()..color = const Color(0xFFFDE047);
      canvas.drawCircle(sunCenter, 22, sunPaint);
    } else if (isNight) {
      // Parlayan Hilal Ay
      final moonCenter = Offset(size.width * 0.8, size.height * 0.16);
      final moonGlow = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFE0F2FE).withOpacity(0.35),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: moonCenter, radius: 45));
      canvas.drawCircle(moonCenter, 45, moonGlow);

      final moonPaint = Paint()..color = const Color(0xFFF1F5F9);
      canvas.drawCircle(moonCenter, 18, moonPaint);
    }

    // ── 3. BULUTLAR (HACİMSEL 3D PUFLAR) ──
    for (var cloud in clouds) {
      final cloudPaint = Paint()
        ..color = isNight
            ? const Color(0xFF1E2538).withOpacity(0.65)
            : Colors.white.withOpacity(weatherType == WeatherType.thunder ? 0.35 : 0.6);

      for (int i = 0; i < cloud.puffOffsets.length; i++) {
        final puff = cloud.puffOffsets[i];
        final r = cloud.puffRadii[i] * cloud.scale;
        final center = Offset(cloud.x + puff.dx * cloud.scale, cloud.y + puff.dy * cloud.scale);
        canvas.drawCircle(center, r, cloudPaint);
      }
    }

    // ── 4. PARÇACIKLAR (YAĞMUR, KAR, YILDIZLAR) ──
    if (weatherType == WeatherType.rainy || weatherType == WeatherType.thunder) {
      for (var p in particles) {
        final rainPaint = Paint()
          ..color = p.color.withOpacity(p.alpha)
          ..strokeWidth = p.size
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(p.x, p.y),
          Offset(p.x + p.vx, p.y + p.length),
          rainPaint,
        );
      }

      // Sıçrayan mini damlacıklar
      for (var sp in splashes) {
        final splashPaint = Paint()
          ..color = const Color(0xFFBAE6FD).withOpacity(sp.alpha)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(sp.x, sp.y), sp.radius, splashPaint);
      }
    } else if (weatherType == WeatherType.snowy) {
      for (var p in particles) {
        final snowPaint = Paint()
          ..color = p.color.withOpacity(p.alpha)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(p.x, p.y), p.size, snowPaint);
      }
    } else if (isNight) {
      // Yıldızlar
      for (var p in particles) {
        final starPaint = Paint()
          ..color = p.color.withOpacity(p.alpha)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(p.x, p.y), p.size, starPaint);
      }
    }

    // ── 5. ŞİMŞEK ÇAKMASI (THUNDER) ──
    if (lightningOpacity > 0.05) {
      final flashPaint = Paint()..color = Colors.white.withOpacity(lightningOpacity * 0.45);
      canvas.drawRect(rect, flashPaint);

      if (lightningBolts.length > 1) {
        final boltPath = Path()..moveTo(lightningBolts.first.dx, lightningBolts.first.dy);
        for (int b = 1; b < lightningBolts.length; b++) {
          boltPath.lineTo(lightningBolts[b].dx, lightningBolts[b].dy);
        }

        final boltPaint = Paint()
          ..color = const Color(0xFFE0F2FE).withOpacity(lightningOpacity)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(boltPath, boltPaint);

        final glowPaint = Paint()
          ..color = const Color(0xFF38BDF8).withOpacity(lightningOpacity * 0.6)
          ..strokeWidth = 6.0
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(boltPath, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AtmosphericCanvasPainter oldDelegate) => true;
}
