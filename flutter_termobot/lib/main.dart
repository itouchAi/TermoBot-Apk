import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'models/thermostat_state.dart';
import 'models/app_settings.dart';
import 'services/esp_service.dart';
import 'screens/thermostat_screen.dart';
import 'screens/weather_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/schedule_screen.dart';
import 'widgets/settings_sheet.dart';
import 'widgets/voice_call_overlay.dart';
import 'widgets/smart_display_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF090D14),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const TermoBotApp());
}

class TermoBotApp extends StatefulWidget {
  const TermoBotApp({super.key});

  @override
  State<TermoBotApp> createState() => _TermoBotAppState();
}

class _TermoBotAppState extends State<TermoBotApp> {
  AppSettings _settings = AppSettings();

  void _updateSettings(AppSettings newSettings) {
    setState(() => _settings = newSettings);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TermoBot 3D',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: MainNavigationScreen(
        settings: _settings,
        onUpdateSettings: _updateSettings,
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onUpdateSettings;

  const MainNavigationScreen({
    super.key,
    required this.settings,
    required this.onUpdateSettings,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  ThermostatState _state = ThermostatState();
  final EspService _espService = EspService();

  // Full-screen overlays
  bool _isCallOverlayOpen = false;
  String _callReason = 'manual_test';
  bool _isSmartDisplayOpen = false;

  // Active Alert Banner
  String? _alertMessage;
  bool _isAlertError = false;

  void _onTargetChanged(double newTarget) {
    setState(() {
      _state = _state.copyWith(targetTemp: newTarget);
      _state = _espService.computeThermostatLogic(_state);
    });
    _espService.sendTargetToEsp(_state.espIp, newTarget);
  }

  void _onSetPreset(double presetTemp) {
    _onTargetChanged(presetTemp);
  }

  void _onToggleRelay() {
    setState(() {
      final next = !_state.isRelayActive;
      _state = _state.copyWith(
        isRelayActive: next,
        flameModulation: next ? 68 : 0,
      );
      if (next && widget.settings.voiceCallEnabled && widget.settings.autoCallOnIgnition) {
        _triggerCall('ignition');
      }
    });
  }

  void _triggerCall(String reason) {
    HapticFeedback.heavyImpact();
    setState(() {
      _callReason = reason;
      _isCallOverlayOpen = true;
    });
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SettingsSheet(
        settings: widget.settings,
        onUpdateSettings: widget.onUpdateSettings,
        onLaunchSmartDisplay: () => setState(() => _isSmartDisplayOpen = true),
        onTriggerTestCall: () => _triggerCall('manual_test'),
        onTriggerDisconnectAlert: () {
          HapticFeedback.heavyImpact();
          setState(() {
            _state = _state.copyWith(isConnected: false);
            _alertMessage = '⚠️ Kombi ESP32 bağlantısı koptu! Isıtma emniyet moduna geçti.';
            _isAlertError = true;
          });
        },
        onTriggerLowBatteryAlert: () {
          HapticFeedback.mediumImpact();
          setState(() {
            _alertMessage = '🪫 Düşük Pil: Oda termostatı pili %14 seviyesine düştü!';
            _isAlertError = false;
          });
        },
        onResetFactorySettings: () {
          setState(() {
            _state = ThermostatState();
            widget.onUpdateSettings(AppSettings());
            _alertMessage = '✓ Fabrika ayarlarına başarıyla sıfırlandı.';
            _isAlertError = false;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCallOverlayOpen) {
      return VoiceCallOverlay(
        callReason: _callReason,
        currentTemp: _state.currentTemp,
        targetTemp: _state.targetTemp,
        onDismiss: () => setState(() => _isCallOverlayOpen = false),
      );
    }

    if (_isSmartDisplayOpen) {
      return SmartDisplayView(
        currentTemp: _state.currentTemp,
        targetTemp: _state.targetTemp,
        isHeating: _state.isRelayActive,
        onDismiss: () => setState(() => _isSmartDisplayOpen = false),
      );
    }

    final screens = [
      ThermostatScreen(
        state: _state,
        settings: widget.settings,
        onTargetChanged: _onTargetChanged,
        onSetPreset: _onSetPreset,
        onToggleRelay: _onToggleRelay,
        onOpenSettings: _showSettingsModal,
        onLaunchSmartDisplay: () => setState(() => _isSmartDisplayOpen = true),
      ),
      const WeatherScreen(),
      const ReportsScreen(),
      const ScheduleScreen(),
    ];

    final titles = [
      'TermoBot 3D',
      'Bölgesel Hava Durumu',
      'Tüketim Analitiği',
      'Haftalık Program',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          // Ambiyans Modu Butonu
          IconButton(
            icon: const Icon(Icons.tv_rounded, color: Colors.white70),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() => _isSmartDisplayOpen = true);
            },
          ),
          // Ayarlar Çarkı
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showSettingsModal();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: screens,
          ),

          // Üst Kayan Sistem Uyarı Banner'ı
          if (_alertMessage != null)
            Positioned(
              top: 10,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _isAlertError ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _isAlertError ? Icons.wifi_off_rounded : Icons.battery_alert_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _alertMessage!,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 18),
                      onPressed: () => setState(() => _alertMessage = null),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.thermostat_rounded),
            label: 'Termostat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wb_sunny_rounded),
            label: 'Hava',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Rapor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm_rounded),
            label: 'Program',
          ),
        ],
      ),
    );
  }
}
