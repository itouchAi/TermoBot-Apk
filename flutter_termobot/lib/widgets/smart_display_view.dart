import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/smart_display_config.dart';
import '../models/app_settings.dart';
import 'luxury_media_bar.dart';
import 'music_equalizer.dart';
import 'smart_display_controls_pill.dart';
import 'media_playlist_modal.dart';
import 'universal_mascot.dart';

class SmartDisplayView extends StatefulWidget {
  final double currentTemp;
  final double targetTemp;
  final bool isHeating;
  final ValueChanged<double> onSetTarget;
  final VoidCallback onDismiss;
  final SmartDisplayConfig? initialConfig;
  final MascotType mascotType;

  const SmartDisplayView({
    super.key,
    required this.currentTemp,
    required this.targetTemp,
    required this.isHeating,
    required this.onSetTarget,
    required this.onDismiss,
    this.initialConfig,
    this.mascotType = MascotType.termobot,
  });

  @override
  State<SmartDisplayView> createState() => _SmartDisplayViewState();
}

class _SmartDisplayViewState extends State<SmartDisplayView>
    with TickerProviderStateMixin {
  late SmartDisplayConfig _config;

  late Timer _clockTimer;
  late Timer _burnInTimer;
  Timer? _slideshowTimer;
  DateTime _now = DateTime.now();

  // OLED burn-in pixel shift
  double _offsetX = 0;
  double _offsetY = 0;

  // Clean Screen mode (tap toggles controls)
  bool _showControls = true;
  Timer? _hideControlsTimer;

  // Playback state
  bool _isPlaying = true;
  bool _isMuted = false;
  int _activeMediaIndex = 0;

  // Modals
  bool _isPlaylistModalOpen = false;
  bool _isThermostatDialOpen = false;

  late AnimationController _ambientController;
  final List<_AmbientParticle> _particles = [];
  final math.Random _rnd = math.Random();

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig ?? const SmartDisplayConfig();

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    // OLED Burn-in pixel shift every 60s
    _burnInTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted && _config.burnInProtection) {
        setState(() {
          _offsetX = (_rnd.nextDouble() * 8) - 4;
          _offsetY = (_rnd.nextDouble() * 8) - 4;
        });
      }
    });

    _initParticles();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 32),
    )..addListener(() {
        for (final p in _particles) {
          p.update(_config.presetTheme);
        }
        if (mounted) setState(() {});
      })..repeat();

    _startSlideshowTimer();
    _scheduleAutoHideControls();
  }

  void _initParticles() {
    _particles.clear();
    for (int i = 0; i < 45; i++) {
      _particles.add(_AmbientParticle.random(_rnd, _config.presetTheme));
    }
  }

  void _startSlideshowTimer() {
    _slideshowTimer?.cancel();
    if (_config.mode == SmartDisplayMode.slideshow && _config.customImages.isNotEmpty) {
      _slideshowTimer = Timer.periodic(
        Duration(seconds: math.max(3, _config.slideshowIntervalSec)),
        (_) {
          if (mounted && _isPlaying) {
            setState(() {
              _activeMediaIndex = (_activeMediaIndex + 1) % _config.customImages.length;
            });
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _burnInTimer.cancel();
    _slideshowTimer?.cancel();
    _hideControlsTimer?.cancel();
    _ambientController.dispose();
    super.dispose();
  }

  void _scheduleAutoHideControls() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _onScreenTap() {
    HapticFeedback.selectionClick();
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleAutoHideControls();
  }

  void _handlePrevious() {
    HapticFeedback.selectionClick();
    setState(() {
      _activeMediaIndex = math.max(0, _activeMediaIndex - 1);
    });
    _scheduleAutoHideControls();
  }

  void _handleNext() {
    HapticFeedback.selectionClick();
    setState(() {
      _activeMediaIndex++;
    });
    _scheduleAutoHideControls();
  }

  String get _currentTrackTitle {
    if (_config.audioTrack == AmbientAudioTrack.none) return 'Sessiz Mod';
    if (_config.customAudioTracks.isNotEmpty) {
      final item = _config.customAudioTracks[_activeMediaIndex % _config.customAudioTracks.length];
      return item.name;
    }
    switch (_config.audioTrack) {
      case AmbientAudioTrack.fireplace:
        return 'Şömine Çatırtısı & Sıcak Kıvılcımlar (HQ)';
      case AmbientAudioTrack.rain:
        return 'Pencereye Vuran Sakin Yağmur Sesi';
      case AmbientAudioTrack.lofi:
        return 'Lo-Fi Akustik Termal Kafe';
      case AmbientAudioTrack.relaxPiano:
        return 'Huzurlu Piyano & Ortam Tınıları';
      case AmbientAudioTrack.nature:
        return 'Doğa Esintisi & Cırcır Böcekleri';
      case AmbientAudioTrack.custom:
        return 'Özel Akış: ${_config.customAudioUrl}';
      default:
        return 'Ambiyans Müziği';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(_now);
    final dateStr = DateFormat('EEEE, d MMMM', 'tr_TR').format(_now);

    final brightnessAlpha = (_config.brightnessPercent / 100.0).clamp(0.1, 1.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onScreenTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── 1. AMBIYANS ARKA PLAN GPU PARÇACIKLARI ──
            Positioned.fill(
              child: Opacity(
                opacity: brightnessAlpha,
                child: CustomPaint(
                  painter: _SmartDisplayBackgroundPainter(
                    particles: _particles,
                    theme: _config.presetTheme,
                    isHeating: widget.isHeating,
                  ),
                ),
              ),
            ),

            // ── 2. MERKEZ VOLUMETRİK GLOW AURA ──
            Center(
              child: AnimatedContainer(
                duration: const Duration(seconds: 1),
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (widget.isHeating ? const Color(0xFFFF6A00) : const Color(0xFF6366F1))
                      .withValues(alpha: 0.10 * brightnessAlpha),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isHeating ? const Color(0xFFFF6A00) : const Color(0xFF6366F1))
                          .withValues(alpha: 0.22 * brightnessAlpha),
                      blurRadius: 130,
                      spreadRadius: 25,
                    ),
                  ],
                ),
              ),
            ),

            // ── 3. ANA İÇERİK KATMANI (BURN-IN KORUMALI) ──
            Transform.translate(
              offset: Offset(_offsetX, _offsetY),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Üst Kontrol Çubuğu (Kayan Şarkı Başlığı, Playlist Butonu, Controls Pill)
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: _showControls ? 1.0 : 0.0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Kayan Marquee Başlık Barı & Playlist Açıcı
                            InkWell(
                              onTap: () {
                                setState(() => _isPlaylistModalOpen = true);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.playlist_play_rounded, color: Color(0xFFF59E0B), size: 18),
                                    const SizedBox(width: 6),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 170),
                                      child: Text(
                                        _currentTrackTitle,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.tune_rounded, color: Colors.white60, size: 14),
                                  ],
                                ),
                              ),
                            ),

                            // Controls Pill (Güneş, Parlaklık Slider, Kırmızı Kapat Butonu)
                            SmartDisplayControlsPill(
                              brightnessPercent: _config.brightnessPercent,
                              onBrightnessChange: (val) {
                                setState(() {
                                  _config = _config.copyWith(brightnessPercent: val);
                                });
                              },
                              onClose: widget.onDismiss,
                            ),
                          ],
                        ),
                      ),

                      // ── MERKEZ: MÜZİK EKOLAYZIR, DİJİTAL SAAT & MASCOT ──
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Canlı Müzik Ekolayzır
                          if (_config.equalizerEnabled)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: MusicEqualizer(
                                enabled: _config.equalizerEnabled,
                                style: _config.equalizerStyle,
                                isPlaying: _isPlaying,
                              ),
                            ),

                          // Dev Dijital Saat
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 92,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -5,
                              fontFamily: 'monospace',
                              color: Colors.white.withValues(alpha: brightnessAlpha),
                              shadows: const [
                                Shadow(color: Colors.black, blurRadius: 25),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.65 * brightnessAlpha),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Smart Display Mascot
                          SizedBox(
                            height: 80,
                            child: UniversalMascot(
                              currentTemp: widget.currentTemp,
                              targetTemp: widget.targetTemp,
                              isHeating: widget.isHeating,
                              type: widget.mascotType,
                            ),
                          ),
                        ],
                      ),

                      // ── ALT: LUXURY MEDIA BAR & CANLI TELEMETRİ / DOKUNMATİK TERMOSTAT ──
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Luxury Media Bar
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 250),
                            opacity: _showControls ? 1.0 : 0.25,
                            child: LuxuryMediaBar(
                              mediaType: _config.mode == SmartDisplayMode.video
                                  ? 'video'
                                  : _config.mode == SmartDisplayMode.slideshow
                                      ? 'image'
                                      : 'audio',
                              isPlaying: _isPlaying,
                              onTogglePlay: () {
                                setState(() => _isPlaying = !_isPlaying);
                              },
                              onPrevious: _handlePrevious,
                              onNext: _handleNext,
                              isMuted: _isMuted,
                              onToggleMute: () {
                                setState(() => _isMuted = !_isMuted);
                              },
                              volume: _config.audioVolume,
                              onVolumeChange: (vol) {
                                setState(() {
                                  _config = _config.copyWith(audioVolume: vol);
                                  _isMuted = false;
                                });
                              },
                              isLoop: _config.isLoop,
                              onToggleLoop: () {
                                setState(() {
                                  _config = _config.copyWith(isLoop: !_config.isLoop);
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Telemetri Kapsülü: Tıklanabilir Dokunmatik Termostat
                          InkWell(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              setState(() => _isThermostatDialOpen = true);
                            },
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF14121E).withValues(alpha: 0.90),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black87,
                                    blurRadius: 20,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Oda Sıcaklığı
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'CANLI ODA',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                      Text(
                                        '${widget.currentTemp.toStringAsFixed(1)}°C',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),

                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 14),
                                    width: 1,
                                    height: 30,
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),

                                  // Hedef Sıcaklık & Ayar İpucu
                                  Row(
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'HEDEF TERMOSTAT',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFF59E0B),
                                            ),
                                          ),
                                          Text(
                                            '${widget.targetTemp.toStringAsFixed(1)}°C',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFFFBBF24),
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.touch_app_rounded,
                                          size: 14,
                                          color: Color(0xFFFCD34D),
                                        ),
                                      ),
                                    ],
                                  ),

                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 14),
                                    width: 1,
                                    height: 30,
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),

                                  // Kombi Durumu
                                  Row(
                                    children: [
                                      Icon(
                                        widget.isHeating
                                            ? Icons.local_fire_department_rounded
                                            : Icons.ac_unit_rounded,
                                        color: widget.isHeating
                                            ? const Color(0xFFFF6A00)
                                            : const Color(0xFF60A5FA),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.isHeating ? 'ATEŞLENDİ' : 'BEKLEMEDE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: widget.isHeating
                                              ? const Color(0xFFFF6A00)
                                              : const Color(0xFF60A5FA),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── 4. TERMOSTAT DOKUNMATİK AYAR MODALI ──
            if (_isThermostatDialOpen)
              _buildThermostatWheelModal(),

            // ── 5. MEDYA & AKIŞ YÖNETİCİSİ MODALI ──
            if (_isPlaylistModalOpen)
              MediaPlaylistModal(
                config: _config,
                onUpdateConfig: (newCfg) {
                  setState(() {
                    _config = newCfg;
                    _initParticles();
                    _startSlideshowTimer();
                  });
                },
                onDismiss: () {
                  setState(() => _isPlaylistModalOpen = false);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThermostatWheelModal() {
    double currentDial = widget.targetTemp;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return GestureDetector(
          onTap: () => setState(() => _isThermostatDialOpen = false),
          child: Container(
            color: Colors.black.withValues(alpha: 0.75),
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {}, // Prevent dismissal on modal tap
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Hızlı Sıcaklık Ayarı',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${currentDial.toStringAsFixed(1)}°C',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFBBF24),
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Stepper buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.remove_circle_rounded, color: Color(0xFFFB7185)),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setModalState(() {
                              currentDial = (currentDial - 0.5).clamp(16.0, 30.0);
                            });
                            widget.onSetTarget(currentDial);
                          },
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF34D399)),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setModalState(() {
                              currentDial = (currentDial + 0.5).clamp(16.0, 30.0);
                            });
                            widget.onSetTarget(currentDial);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      ),
                      onPressed: () => setState(() => _isThermostatDialOpen = false),
                      child: const Text('Tamam', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AmbientParticle {
  double x;
  double y;
  double speedY;
  double speedX;
  double radius;
  double opacity;

  _AmbientParticle({
    required this.x,
    required this.y,
    required this.speedY,
    required this.speedX,
    required this.radius,
    required this.opacity,
  });

  factory _AmbientParticle.random(math.Random rnd, PresetVisualTheme theme) {
    double speedY;
    double speedX = 0;
    double radius;

    switch (theme) {
      case PresetVisualTheme.fireplace:
        speedY = 0.003 + (rnd.nextDouble() * 0.006);
        speedX = (rnd.nextDouble() - 0.5) * 0.002;
        radius = 1.5 + (rnd.nextDouble() * 3.0);
        break;
      case PresetVisualTheme.rainyWindow:
        speedY = -(0.01 + (rnd.nextDouble() * 0.02)); // falls down
        speedX = (rnd.nextDouble() - 0.5) * 0.001;
        radius = 1.0 + (rnd.nextDouble() * 2.0);
        break;
      case PresetVisualTheme.winterSnow:
        speedY = -(0.002 + (rnd.nextDouble() * 0.004));
        speedX = (rnd.nextDouble() - 0.5) * 0.002;
        radius = 2.0 + (rnd.nextDouble() * 3.5);
        break;
      case PresetVisualTheme.aurora:
        speedY = 0.001;
        speedX = 0.002;
        radius = 3.0 + (rnd.nextDouble() * 5.0);
        break;
      default:
        speedY = 0.002;
        radius = 1.5;
        break;
    }

    return _AmbientParticle(
      x: rnd.nextDouble(),
      y: rnd.nextDouble(),
      speedY: speedY,
      speedX: speedX,
      radius: radius,
      opacity: 0.2 + (rnd.nextDouble() * 0.6),
    );
  }

  void update(PresetVisualTheme theme) {
    if (theme == PresetVisualTheme.rainyWindow || theme == PresetVisualTheme.winterSnow) {
      y -= speedY;
      x += speedX;
      if (y > 1.0) {
        y = 0.0;
        x = math.Random().nextDouble();
      }
    } else {
      y -= speedY;
      x += speedX;
      if (y < 0) {
        y = 1.0;
        x = math.Random().nextDouble();
      }
    }
  }
}

class _SmartDisplayBackgroundPainter extends CustomPainter {
  final List<_AmbientParticle> particles;
  final PresetVisualTheme theme;
  final bool isHeating;

  _SmartDisplayBackgroundPainter({
    required this.particles,
    required this.theme,
    required this.isHeating,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (theme == PresetVisualTheme.minimalBlack) {
      // Pure deep black for maximum OLED efficiency
      return;
    }

    Color baseColor;
    switch (theme) {
      case PresetVisualTheme.fireplace:
        baseColor = isHeating ? const Color(0xFFFF8C32) : const Color(0xFFF97316);
        break;
      case PresetVisualTheme.rainyWindow:
        baseColor = const Color(0xFF38BDF8);
        break;
      case PresetVisualTheme.winterSnow:
        baseColor = const Color(0xFFE2E8F0);
        break;
      case PresetVisualTheme.sunsetForest:
        baseColor = const Color(0xFFF43F5E);
        break;
      case PresetVisualTheme.aurora:
        baseColor = const Color(0xFF34D399);
        break;
      default:
        baseColor = const Color(0xFF818CF8);
    }

    for (final p in particles) {
      final paint = Paint()
        ..color = baseColor.withValues(alpha: p.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SmartDisplayBackgroundPainter oldDelegate) => true;
}
