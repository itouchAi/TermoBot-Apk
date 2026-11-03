import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'universal_mascot.dart';

enum ScreenSaverTheme {
  black,
  cyberStation,
  warmHearth,
  midnightPurple,
}

class MascotScreenSaverOverlay extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onDismiss;
  final MascotType mascotType;
  final double currentTemp;
  final double targetTemp;
  final bool isHeating;
  final ScreenSaverTheme theme;

  const MascotScreenSaverOverlay({
    super.key,
    required this.isVisible,
    required this.onDismiss,
    this.mascotType = MascotType.termobot,
    this.currentTemp = 21.8,
    this.targetTemp = 22.5,
    this.isHeating = false,
    this.theme = ScreenSaverTheme.black,
  });

  @override
  State<MascotScreenSaverOverlay> createState() => _MascotScreenSaverOverlayState();
}

class _MascotScreenSaverOverlayState extends State<MascotScreenSaverOverlay> {
  Timer? _clockTimer;
  Timer? _pixelShiftTimer;
  String _timeStr = '12:00:00';
  String _dateStr = '1 Ocak Pazartesi';

  // OLED Yanma Önleyici Piksel Kaydırma Değerleri (±12px drift)
  double _shiftX = 0.0;
  double _shiftY = 0.0;
  bool _wakingUp = false;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (t) => _updateClock());

    // 60 saniyede bir hafifçe kaydır (OLED burn-in koruması)
    _pixelShiftTimer = Timer.periodic(const Duration(seconds: 60), (t) {
      if (!mounted) return;
      setState(() {
        _shiftX = (_shiftX == 0.0) ? 8.0 : (_shiftX == 8.0) ? -8.0 : 0.0;
        _shiftY = (_shiftY == 0.0) ? 6.0 : (_shiftY == 6.0) ? -6.0 : 0.0;
      });
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pixelShiftTimer?.cancel();
    super.dispose();
  }

  void _updateClock() {
    if (!mounted) return;
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');

    final months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    final days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

    setState(() {
      _timeStr = '$h:$m:$s';
      _dateStr = '${now.day} ${months[now.month - 1]} ${days[now.weekday - 1]}';
    });
  }

  void _handleTapToWake() {
    if (_wakingUp) return;
    HapticFeedback.mediumImpact();

    setState(() => _wakingUp = true);

    // 1.5 saniyelik uyanma animasyonundan sonra kapat
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _wakingUp = false);
        widget.onDismiss();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    // Arka Plan Renk / Gradyanı
    BoxDecoration bgDecoration;
    switch (widget.theme) {
      case ScreenSaverTheme.black:
        bgDecoration = const BoxDecoration(color: Colors.black);
        break;
      case ScreenSaverTheme.cyberStation:
        bgDecoration = const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.1,
            colors: [Color(0xFF0F1E36), Color(0xFF070B14), Colors.black],
          ),
        );
        break;
      case ScreenSaverTheme.warmHearth:
        bgDecoration = const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, 0.4),
            radius: 1.2,
            colors: [Color(0xFF2E1508), Color(0xFF140803), Colors.black],
          ),
        );
        break;
      case ScreenSaverTheme.midnightPurple:
        bgDecoration = const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Color(0xFF1E122C), Color(0xFF0B0612), Colors.black],
          ),
        );
        break;
    }

    return GestureDetector(
      onTap: _handleTapToWake,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: bgDecoration,
        child: SafeArea(
          child: AnimatedContainer(
            duration: const Duration(seconds: 2),
            transform: Matrix4.translationValues(_shiftX, _shiftY, 0),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ── ÜST BAR: TARİH & DURUM ROZETİ ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _dateStr,
                      style: const TextStyle(fontSize: 13, color: Colors.white54, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.isHeating ? const Color(0xFFFF8C32).withOpacity(0.2) : Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.isHeating ? const Color(0xFFFF8C32).withOpacity(0.5) : Colors.white12,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.isHeating ? Icons.local_fire_department_rounded : Icons.eco_rounded,
                            size: 13,
                            color: widget.isHeating ? const Color(0xFFFF8C32) : const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.isHeating ? 'Kombi Aktif' : 'Eko Bekleme',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: widget.isHeating ? const Color(0xFFFF8C32) : const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── ORTA BÖLÜM: BÜYÜK DİJİTAL SAAT & YÜZEN MASKOT ──
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dijital Saat
                    Text(
                      _timeStr,
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontFamily: 'monospace',
                        letterSpacing: -2,
                        shadows: [
                          Shadow(color: Color(0xFF38BDF8), blurRadius: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Maskot
                    UniversalMascot(
                      type: widget.mascotType,
                      currentTemp: widget.currentTemp,
                      targetTemp: widget.targetTemp,
                      isHeating: widget.isHeating,
                      size: 96,
                      interactive: true,
                      onTap: _handleTapToWake,
                    ),

                    const SizedBox(height: 18),

                    // Anlık Sıcaklık / Hedef Bilgi Kapsülü
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14121E).withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${widget.currentTemp.toStringAsFixed(1)}°C',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace'),
                          ),
                          const SizedBox(width: 8),
                          const Text('•', style: TextStyle(color: Colors.white38)),
                          const SizedBox(width: 8),
                          Text(
                            'Hedef: ${widget.targetTemp.toStringAsFixed(1)}°C',
                            style: const TextStyle(fontSize: 13, color: Color(0xFFFFB800), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── ALT BİLGİ: DOKUN UYANDIR METNİ ──
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_wakingUp)
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wb_sunny_rounded, color: Color(0xFFFFB800), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Günaydın! TermoBot uyanıyor...',
                            style: TextStyle(color: Color(0xFFFFB800), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    else
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.touch_app_rounded, color: Colors.white38, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Uyanmak için ekrana dokunun',
                            style: TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    const Text(
                      'OLED Piksel Koruma Aktif (Her 60s kayar)',
                      style: TextStyle(fontSize: 9, color: Colors.white24, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
