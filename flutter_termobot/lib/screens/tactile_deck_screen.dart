import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/thermostat_state.dart';
import '../models/app_settings.dart';
import '../widgets/exact_tactile_dial.dart';
import '../widgets/universal_mascot.dart';
import '../utils/i18n.dart';
import 'weather_screen.dart';
import 'reports_screen.dart';
import 'schedule_screen.dart';

class TactileDeckScreen extends StatefulWidget {
  final ThermostatState state;
  final AppSettings settings;
  final List<String> tabOrder;
  final String currentTheme;
  final int paletteIdx;
  final ValueChanged<double> onTargetChanged;
  final ValueChanged<double> onSetPreset;
  final VoidCallback onToggleRelay;
  final VoidCallback onOpenSettings;
  final VoidCallback onLaunchSmartDisplay;
  final VoidCallback onOpenCustomizer;
  final VoidCallback onOpenThemeSelector;
  final VoidCallback onOpenVoiceAssistant;
  final VoidCallback onToggleLanguage;

  const TactileDeckScreen({
    super.key,
    required this.state,
    required this.settings,
    this.tabOrder = const ['genel', 'hava', 'rapor', 'program'],
    this.currentTheme = 'tactile_deck',
    this.paletteIdx = 3,
    required this.onTargetChanged,
    required this.onSetPreset,
    required this.onToggleRelay,
    required this.onOpenSettings,
    required this.onLaunchSmartDisplay,
    required this.onOpenCustomizer,
    required this.onOpenThemeSelector,
    required this.onOpenVoiceAssistant,
    required this.onToggleLanguage,
  });

  @override
  State<TactileDeckScreen> createState() => _TactileDeckScreenState();
}

class _TactileDeckScreenState extends State<TactileDeckScreen> {
  late PageController _pageController;
  int _activePageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    HapticFeedback.selectionClick();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  String _getActiveModeName() {
    final t = widget.state.targetTemp;
    if ((t - 20.0).abs() < 0.25) return 'EKO';
    if ((t - 22.5).abs() < 0.25) return 'KONFOR';
    if ((t - 18.5).abs() < 0.25) return 'GECE';
    if ((t - 25.0).abs() < 0.25) return 'BOOST';
    return 'MANUEL';
  }

  Widget _buildCardForId(String id) {
    switch (id) {
      case 'genel':
        return _buildTactileDeckCard();
      case 'hava':
        return _buildCardWrapper(
          title: '🌤️ Bölgesel Hava Durumu & 5 Günlük Tahmin',
          child: const WeatherScreen(),
        );
      case 'rapor':
        return _buildCardWrapper(
          title: '📊 24s Sıcaklık & Tüketim Analitiği',
          child: ReportsScreen(
            currentTemp: widget.state.currentTemp,
            targetTemp: widget.state.targetTemp,
            humidity: widget.state.humidity,
            waterPressure: widget.state.waterPressure,
            isHeating: widget.state.isRelayActive,
            flamePercent: widget.state.flameModulation,
          ),
        );
      case 'program':
        return _buildCardWrapper(
          title: '⏰ Haftalık Zaman Planı & Tüketim',
          child: ScheduleScreen(
            dailyRunMinutes: 145,
            flamePercent: widget.state.flameModulation,
          ),
        );
      default:
        return _buildTactileDeckCard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderedTabs = widget.tabOrder;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF262330),
            Color(0xFF1B1924),
            Color(0xFF0F0E15),
          ],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── TOP NAV HEADER (IMAGE_BC3BC9F4.PNG) ──
                _buildTopNavHeader(),

                // ── SWIPEABLE 3D CAROUSEL / MAIN CONTENT ──
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (idx) {
                      HapticFeedback.selectionClick();
                      setState(() => _activePageIndex = idx);
                    },
                    children: orderedTabs.map((id) => _buildCardForId(id)).toList(),
                  ),
                ),

                // ── BOTTOM DOT INDICATOR BAR ──
                _buildBottomNavDots(orderedTabs.length),
              ],
            ),

            // ── CANLI SEVİMLİ MASKOT (Açık ise sağ alt köşede) ──
            if (widget.settings.mascotEnabled)
              Positioned(
                right: 14,
                bottom: 40,
                child: MascotWidget(
                  isHeating: widget.state.isRelayActive,
                  currentTemp: widget.state.currentTemp,
                  targetTemp: widget.state.targetTemp,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF161422),
        border: Border(
          bottom: BorderSide(color: Color(0x1FFFFFFF), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Orange Flame Icon Circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF9900), Color(0xFFFF5500)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF7700).withOpacity(widget.state.isRelayActive ? 0.7 : 0.3),
                  blurRadius: widget.state.isRelayActive ? 14 : 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 8),

          // Title & Location Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'TermoBot',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Ev (İstanbul)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Language / Region Badge (TR TR / EN EN)
          ValueListenableBuilder<Language>(
            valueListenable: I18n.languageNotifier,
            builder: (context, lang, _) {
              final isTr = lang == Language.tr;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  I18n.toggleLanguage();
                  widget.onToggleLanguage();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1926),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF0C0B10),
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(isTr ? 'TR' : 'EN', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(width: 2),
                      Text(isTr ? 'TR' : 'US', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFFFB800))),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),

          // ⚡ 60 FPS Native Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1926),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF0C0B10),
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 12),
                SizedBox(width: 2),
                Text(
                  '60 FPS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Tema Seçici (Palette / Equalizer)
          _buildTopIconBtn(
            icon: Icons.palette_outlined,
            onTap: widget.onOpenThemeSelector,
          ),
          const SizedBox(width: 4),

          // Ekran Sıralama Düzenleyici
          _buildTopIconBtn(
            icon: Icons.tune_rounded,
            onTap: widget.onOpenCustomizer,
          ),
          const SizedBox(width: 4),

          // Akıllı Sesli Asistan
          _buildTopIconBtn(
            icon: Icons.mic_rounded,
            onTap: widget.onOpenVoiceAssistant,
          ),
          const SizedBox(width: 4),

          // TV / Smart Display Icon
          _buildTopIconBtn(
            icon: Icons.tv_rounded,
            onTap: widget.onLaunchSmartDisplay,
          ),
          const SizedBox(width: 4),

          // Settings Gear Icon
          _buildTopIconBtn(
            icon: Icons.settings_outlined,
            onTap: widget.onOpenSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildTopIconBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF1B1926),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF0C0B10),
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, color: Colors.white70, size: 16),
        ),
      ),
    );
  }

  Widget _buildTactileDeckCard() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B1924),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.14), width: 1.2),
          boxShadow: [
            const BoxShadow(
              color: Color(0xE6000000),
              blurRadius: 36,
              offset: Offset(0, 18),
            ),
            if (widget.state.isRelayActive)
              BoxShadow(
                color: const Color(0xFFFF8C3C).withOpacity(0.25),
                blurRadius: 30,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Column(
          children: [
            // Card Title Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Text('🏠', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Text(
                        'Termostat & Kombi Ana Kontrol',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    '👈 👉',
                    style: TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0x1FFFFFFF), height: 1),
            const SizedBox(height: 12),

            // ── COMPACT TACTILE TELEMETRY BAR ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildTactileTelemetryBar(),
            ),

            const SizedBox(height: 16),

            // ── CENTER EXACT 3D ROTARY DIAL ──
            ExactTactileDial(
              targetTemp: widget.state.targetTemp,
              currentTemp: widget.state.currentTemp,
              isHeating: widget.state.isRelayActive,
              activeModeName: _getActiveModeName(),
              onSetTarget: widget.onTargetChanged,
            ),

            const SizedBox(height: 20),

            // ── 4 PRESET CAPSULE BUTTONS (EKO, KONFOR, GECE, BOOST) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildPresetCapsuleButtons(),
            ),

            const SizedBox(height: 14),

            // ── CANLI REAKTİF MASKOT (TermoBot, Flamey, Frosty) ──
            if (widget.settings.mascotEnabled) ...[
              UniversalMascot(
                type: _resolveMascotType(widget.settings.mascotType),
                currentTemp: widget.state.currentTemp,
                targetTemp: widget.state.targetTemp,
                isHeating: widget.state.isRelayActive,
                size: 74,
                interactive: true,
              ),
              const SizedBox(height: 10),
            ],

            // Hint Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Kadran üzerindeki turuncu bar çizgisine dokunarak hedefi ayarlayabilirsiniz',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.4),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  MascotType _resolveMascotType(String typeStr) {
    if (typeStr == 'flamey') return MascotType.flamey;
    if (typeStr == 'frosty') return MascotType.frosty;
    return MascotType.termobot;
  }

  Widget _buildTactileTelemetryBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2733),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF0C0B10),
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Colors.black54,
            offset: Offset(0, 8),
            blurRadius: 14,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Oda Sıcaklığı
          Row(
            children: [
              const Text(
                'ODA: ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  color: Color(0xFFD8B4FE),
                ),
              ),
              Text(
                '${widget.state.currentTemp.toStringAsFixed(1)}°C',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const Text('|', style: TextStyle(color: Colors.white24, fontSize: 11)),

          // 2. Basınç
          Row(
            children: [
              const Text(
                'BASINÇ: ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  color: Color(0xFFD8B4FE),
                ),
              ),
              Text(
                '${widget.state.waterPressure.toStringAsFixed(1)} Bar',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const Text('|', style: TextStyle(color: Colors.white24, fontSize: 11)),

          // 3. Hedef
          Row(
            children: [
              const Text(
                'HEDEF: ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  color: Color(0xFFD8B4FE),
                ),
              ),
              Text(
                '${widget.state.targetTemp.toStringAsFixed(1)}°',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  color: Colors.white,
                ),
              ),
              if (widget.state.isRelayActive) ...[
                const SizedBox(width: 2),
                const Icon(Icons.local_fire_department, color: Color(0xFFFF7A1A), size: 14),
              ],
            ],
          ),

          const Text('|', style: TextStyle(color: Colors.white24, fontSize: 11)),

          // 4. Pil
          const Row(
            children: [
              Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
              SizedBox(width: 4),
              Text(
                '%92',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetCapsuleButtons() {
    final presets = [
      {'label': 'EKO', 'temp': 20.0, 'icon': '🍃'},
      {'label': 'KONFOR', 'temp': 22.5, 'icon': '🔥'},
      {'label': 'GECE', 'temp': 18.5, 'icon': '🌙'},
      {'label': 'BOOST', 'temp': 25.0, 'icon': '⚡'},
    ];

    return Row(
      children: presets.map((p) {
        final label = p['label'] as String;
        final temp = p['temp'] as double;
        final icon = p['icon'] as String;
        final isActive = (widget.state.targetTemp - temp).abs() < 0.25;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.onSetPreset(temp);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                transform: Matrix4.translationValues(0, isActive ? 3 : 0, 0),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: isActive
                      ? const RadialGradient(
                          center: Alignment(0.0, 0.0),
                          radius: 0.9,
                          colors: [
                            Color(0xFFFF8C32),
                            Color(0xFFD25014),
                            Color(0xFF2E2420),
                          ],
                          stops: [0.0, 0.65, 1.0],
                        )
                      : const RadialGradient(
                          center: Alignment(0.0, -0.4),
                          radius: 0.8,
                          colors: [
                            Color(0xFF403C4A),
                            Color(0xFF2A2734),
                          ],
                        ),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFFFFC896).withOpacity(0.55)
                        : Colors.white.withOpacity(0.16),
                    width: 1.0,
                  ),
                  boxShadow: isActive
                      ? [
                          const BoxShadow(
                            color: Color(0xFF0C0B10),
                            offset: Offset(0, 3),
                            blurRadius: 0,
                          ),
                          BoxShadow(
                            color: const Color(0xFFFF8C32).withOpacity(0.65),
                            offset: const Offset(0, 4),
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                        ]
                      : const [
                          BoxShadow(
                            color: Color(0xFF0C0B10),
                            offset: Offset(0, 5),
                            blurRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black54,
                            offset: Offset(0, 8),
                            blurRadius: 12,
                          ),
                        ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isActive ? const Color(0xFFFFF7ED) : const Color(0xFFCFC9DA),
                        shadows: isActive
                            ? const [
                                Shadow(
                                  color: Color(0xFFFF9A4A),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    Text(
                      '${temp.toStringAsFixed(1)}°',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        color: isActive ? const Color(0xFFFDE68A) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCardWrapper({required String title, required Widget child}) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B1924),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.14), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0xE6000000),
              blurRadius: 36,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Text('👈 👉', style: TextStyle(fontSize: 11, color: Colors.white38)),
                ],
              ),
            ),
            const Divider(color: Color(0x1FFFFFFF), height: 1),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavDots(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          final isSelected = _activePageIndex == index;
          return GestureDetector(
            onTap: () => _goToPage(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isSelected ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF8C32) : Colors.white24,
                borderRadius: BorderRadius.circular(3),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF8C32).withOpacity(0.7),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}
