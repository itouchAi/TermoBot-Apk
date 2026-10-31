import 'package:flutter/material.dart';
import '../models/thermostat_state.dart';
import '../widgets/tactile_dial.dart';
import '../widgets/telemetry_cards.dart';
import '../theme/app_theme.dart';

class ThermostatScreen extends StatelessWidget {
  final ThermostatState state;
  final ValueChanged<double> onTargetChanged;
  final ValueChanged<double> onSetPreset;
  final VoidCallback onToggleRelay;

  const ThermostatScreen({
    super.key,
    required this.state,
    required this.onTargetChanged,
    required this.onSetPreset,
    required this.onToggleRelay,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: state.isConnected ? AppTheme.greenEco : Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (state.isConnected ? AppTheme.greenEco : Colors.red).withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.isConnected ? 'ESP32 Online • ${state.espIp}' : 'Bağlantı Aranıyor...',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${state.currentTemp.toStringAsFixed(1)}°C / %${state.humidity.toInt()}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.flameAmber,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Central GPU-accelerated Tactile Dial
          TactileDialWidget(
            currentTemp: state.currentTemp,
            targetTemp: state.targetTemp,
            isHeating: state.isRelayActive,
            onTargetChanged: onTargetChanged,
          ),
          const SizedBox(height: 24),

          // Telemetry and Modes
          TelemetryCards(
            state: state,
            onSetPreset: onSetPreset,
            onToggleRelay: onToggleRelay,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
