import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'models/thermostat_state.dart';
import 'models/app_settings.dart';
import 'services/esp_service.dart';
import 'services/sound_synthesis_service.dart';
import 'services/haptics_service.dart';
import 'screens/tactile_deck_screen.dart';
import 'widgets/settings_sheet.dart';
import 'widgets/widget_customizer_modal.dart';
import 'widgets/theme_selector_modal.dart';
import 'widgets/voice_assistant_modal.dart';
import 'widgets/startup_boot_splash.dart';
import 'widgets/voice_call_overlay.dart';
import 'widgets/smart_display_view.dart';
import 'widgets/mascot_screen_saver_overlay.dart';
import 'widgets/universal_mascot.dart';
import 'utils/i18n.dart';
import 'services/telegram_bot_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await I18n.init();
  await HapticsService.init();
  await SoundSynthesisService.init();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0F0E15),
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
      title: 'TermoBot',
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
  ThermostatState _state = ThermostatState();
  final EspService _espService = EspService();

  // Boot status
  bool _isBooted = false;

  // Theme & Performance
  String _currentTheme = 'tactile_deck';
  int _paletteIdx = 3;
  bool _isUltraPerformance = true;

  // Screen ordering
  List<String> _tabOrder = ['genel', 'hava', 'rapor', 'program'];

  // Full-screen overlays
  bool _isCallOverlayOpen = false;
  String _callReason = 'manual_test';
  bool _isSmartDisplayOpen = false;
  bool _isScreenSaverOpen = false;

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
      SoundSynthesisService.playRelayClick(isEngaged: next);
      _state = _state.copyWith(
        isRelayActive: next,
        flameModulation: next ? 68 : 0,
      );
      if (next && widget.settings.voiceCallEnabled && widget.settings.autoCallOnIgnition) {
        _triggerCall('ignition');
      }
      if (next && widget.settings.telegramAlertsEnabled && widget.settings.telegramToken.isNotEmpty) {
        TelegramBotService.sendBoilerAlert(
          botToken: widget.settings.telegramToken,
          chatId: widget.settings.telegramChatId,
          eventType: 'ignition',
          currentTemp: _state.currentTemp,
          targetTemp: _state.targetTemp,
          isHeating: true,
        );
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
        onLaunchScreenSaver: () => setState(() => _isScreenSaverOpen = true),
        onTriggerTestCall: () => _triggerCall('manual_test'),
        onTriggerDisconnectAlert: () {
          SoundSynthesisService.playWarningAlert(WarningSoundType.connection);
          setState(() {
            _state = _state.copyWith(isConnected: false);
            _alertMessage = '⚠️ Kombi ESP32 bağlantısı koptu! Isıtma emniyet moduna geçti.';
            _isAlertError = true;
          });
        },
        onTriggerLowBatteryAlert: () {
          SoundSynthesisService.playWarningAlert(WarningSoundType.battery);
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

  void _showCustomizerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WidgetCustomizerModal(
        tabOrder: _tabOrder,
        onUpdateTabOrder: (newOrder) => setState(() => _tabOrder = newOrder),
      ),
    );
  }

  void _showThemeSelectorModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ThemeSelectorModal(
        currentTheme: _currentTheme,
        onSelectTheme: (th) => setState(() => _currentTheme = th),
        selectedPaletteIdx: _paletteIdx,
        onSelectPalette: (idx) => setState(() => _paletteIdx = idx),
        isUltraPerformance: _isUltraPerformance,
        onTogglePerformance: (val) => setState(() => _isUltraPerformance = val),
      ),
    );
  }

  void _showVoiceAssistantModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoiceAssistantModal(
        currentTemp: _state.currentTemp,
        targetTemp: _state.targetTemp,
        isHeating: _state.isRelayActive,
        onSetTarget: _onTargetChanged,
        onToggleRelay: _onToggleRelay,
        onNavigateToTab: (idx) {
          // Switch tab order
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isBooted && widget.settings.startupSplashEnabled) {
      return StartupBootSplash(
        onFinish: () => setState(() => _isBooted = true),
      );
    }

    if (_isCallOverlayOpen) {
      return VoiceCallOverlay(
        callReason: _callReason,
        currentTemp: _state.currentTemp,
        targetTemp: _state.targetTemp,
        onDismiss: () => setState(() => _isCallOverlayOpen = false),
      );
    }

    if (_isSmartDisplayOpen) {
      MascotType mType = MascotType.termobot;
      if (widget.settings.mascotType == 'flamey') mType = MascotType.flamey;
      if (widget.settings.mascotType == 'frosty') mType = MascotType.frosty;

      return SmartDisplayView(
        currentTemp: _state.currentTemp,
        targetTemp: _state.targetTemp,
        isHeating: _state.isRelayActive,
        onSetTarget: _onTargetChanged,
        onDismiss: () => setState(() => _isSmartDisplayOpen = false),
        mascotType: mType,
      );
    }

    if (_isScreenSaverOpen) {
      MascotType mType = MascotType.termobot;
      if (widget.settings.mascotType == 'flamey') mType = MascotType.flamey;
      if (widget.settings.mascotType == 'frosty') mType = MascotType.frosty;

      return MascotScreenSaverOverlay(
        isVisible: true,
        mascotType: mType,
        currentTemp: _state.currentTemp,
        targetTemp: _state.targetTemp,
        isHeating: _state.isRelayActive,
        onDismiss: () => setState(() => _isScreenSaverOpen = false),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E15),
      body: Stack(
        children: [
          // ── IMMERSIVE TACTILE DECK & CAROUSEL (PIXEL-IDENTICAL TO IMAGE_BC3BC9F4.PNG) ──
          TactileDeckScreen(
            state: _state,
            settings: widget.settings,
            tabOrder: _tabOrder,
            currentTheme: _currentTheme,
            paletteIdx: _paletteIdx,
            onTargetChanged: _onTargetChanged,
            onSetPreset: _onSetPreset,
            onToggleRelay: _onToggleRelay,
            onOpenSettings: _showSettingsModal,
            onLaunchSmartDisplay: () => setState(() => _isSmartDisplayOpen = true),
            onOpenCustomizer: _showCustomizerModal,
            onOpenThemeSelector: _showThemeSelectorModal,
            onOpenVoiceAssistant: _showVoiceAssistantModal,
            onToggleLanguage: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dil: Türkçe (TR) Aktif'),
                  duration: Duration(seconds: 1),
                  backgroundColor: Color(0xFF1B1926),
                ),
              );
            },
          ),

          // ── TOP FLOATING ALERT BANNER (KOPUK BAĞLANTI / DÜŞÜK PİL) ──
          if (_alertMessage != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _isAlertError ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _isAlertError ? Icons.wifi_off_rounded : Icons.battery_alert_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _alertMessage!,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _alertMessage = null),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
