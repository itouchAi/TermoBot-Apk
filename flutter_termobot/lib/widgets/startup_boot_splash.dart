import 'package:flutter/material.dart';

class StartupBootSplash extends StatefulWidget {
  final VoidCallback onFinish;

  const StartupBootSplash({super.key, required this.onFinish});

  @override
  State<StartupBootSplash> createState() => _StartupBootSplashState();
}

class _StartupBootSplashState extends State<StartupBootSplash> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _progress = 0;
  String _statusText = 'Donanım sensörleri taranıyor...';

  final List<String> _stages = [
    'Donanım sensörleri taranıyor...',
    'ESP32 Wi-Fi köprüsü kontrol ediliyor...',
    '0.4°C histerezis algoritması yüklendi...',
    'AES-256 güvenlik kasası doğrulandı...',
    'Sistem Hazır! 120 FPS GPU Aktif.',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

    _ctrl.addListener(() {
      final p = (_ctrl.value * 100).toInt();
      final stageIdx = ((_ctrl.value * _stages.length).toInt()).clamp(0, _stages.length - 1);
      setState(() {
        _progress = p;
        _statusText = _stages[stageIdx];
      });
    });

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 250), widget.onFinish);
      }
    });

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0A13),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Rozeti
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFF9900), Color(0xFFFF5500)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7700).withOpacity(0.6),
                      blurRadius: 35,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 52),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'TermoBot 3D',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Akıllı Kombi & Termostat İşletim Sistemi',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 36),

              // Yükleme İlerleme Çubuğu
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _ctrl.value,
                  backgroundColor: const Color(0xFF1E1B29),
                  color: const Color(0xFFFF8C32),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 14),

              // Yüzde ve Aşama Bilgisi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _statusText,
                      style: const TextStyle(fontSize: 10.5, color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$_progress%',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Color(0xFFFFB800)),
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
