import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'models/thermostat_state.dart';
import 'services/esp_service.dart';
import 'screens/thermostat_screen.dart';
import 'screens/weather_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/schedule_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF090D16),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const TermoBotApp());
}

class TermoBotApp extends StatelessWidget {
  const TermoBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TermoBot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  ThermostatState _state = ThermostatState();
  final EspService _espService = EspService();

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
      _state = _state.copyWith(
        isRelayActive: !_state.isRelayActive,
        flameModulation: !_state.isRelayActive ? 65 : 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ThermostatScreen(
        state: _state,
        onTargetChanged: _onTargetChanged,
        onSetPreset: _onSetPreset,
        onToggleRelay: _onToggleRelay,
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
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppTheme.textSecondary),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showSettingsModal(context);
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
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

  void _showSettingsModal(BuildContext context) {
    final ipController = TextEditingController(text: _state.espIp);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'ESP32 & Donanım Ayarları',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ipController,
              decoration: InputDecoration(
                labelText: 'ESP32 Yerel IP Adresi',
                labelStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.flameOrange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                setState(() {
                  _state = _state.copyWith(espIp: ipController.text.trim());
                });
                Navigator.pop(ctx);
              },
              child: const Text(
                'Kaydet ve Bağlan',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
