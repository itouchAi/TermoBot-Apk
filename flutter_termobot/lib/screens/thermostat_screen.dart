import 'package:flutter/material.dart';
import '../models/thermostat_state.dart';
import '../models/app_settings.dart';
import '../widgets/tactile_dial.dart';
import '../widgets/holographic_rings.dart';
import '../widgets/telemetry_cards.dart';
import '../widgets/mascot_widget.dart';

class ThermostatScreen extends StatelessWidget {
  final ThermostatState state;
  final AppSettings settings;
  final ValueChanged<double> onTargetChanged;
  final ValueChanged<double> onSetPreset;
  final VoidCallback onToggleRelay;
  final VoidCallback onOpenSettings;
  final VoidCallback onLaunchSmartDisplay;

  const ThermostatScreen({
    super.key,
    required this.state,
    required this.settings,
    required this.onTargetChanged,
    required this.onSetPreset,
    required this.onToggleRelay,
    required this.onOpenSettings,
    required this.onLaunchSmartDisplay,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Üst Durum & Telemetri Kapsülü (Bağlantı, Pil, Basınç)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF131926),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ESP32 Durumu
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: state.isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (state.isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                                .withOpacity(0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.isConnected ? 'ESP32 Online • ${state.espIp}' : 'Bağlantı Hatası!',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: state.isConnected ? Colors.white70 : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),

                // Sensör Pili & Hızlı Eylemler
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Text('🔋', style: TextStyle(fontSize: 10)),
                          SizedBox(width: 4),
                          Text('%92',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.tv_rounded, color: Colors.white70, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onLaunchSmartDisplay,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 2. Merkez: 3D Holografik Morfolojik Halkalar + Tactile Dial
          Stack(
            alignment: Alignment.center,
            children: [
              // GPU 3D Dalgalı Halkalar
              HolographicRingsWidget(
                isHeating: state.isRelayActive,
                flamePercent: state.flameModulation.toDouble(),
                activeTheme: settings.activeTheme,
              ),

              // Dokunsal Döner Termostat Kadranı
              TactileDialWidget(
                currentTemp: state.currentTemp,
                targetTemp: state.targetTemp,
                isHeating: state.isRelayActive,
                flamePercent: state.flameModulation,
                onTargetChanged: onTargetChanged,
              ),

              // Sağ Alt Köşe: Sevimli Canlı Maskot (Açık ise)
              if (settings.mascotEnabled)
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: MascotWidget(
                    isHeating: state.isRelayActive,
                    currentTemp: state.currentTemp,
                    targetTemp: state.targetTemp,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // 3. Telemetri Kartları & Hızlı Önayar Modları
          TelemetryCards(
            state: state,
            onSetPreset: onSetPreset,
            onToggleRelay: onToggleRelay,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
