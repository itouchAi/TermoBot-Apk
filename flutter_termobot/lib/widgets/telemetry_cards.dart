import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/thermostat_state.dart';

class TelemetryCards extends StatelessWidget {
  final ThermostatState state;
  final ValueChanged<double> onSetPreset;
  final VoidCallback onToggleRelay;

  const TelemetryCards({
    super.key,
    required this.state,
    required this.onSetPreset,
    required this.onToggleRelay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Quick Mode Selectors (Eco, Konfor, Boost)
        Row(
          children: [
            _buildModePill(
              title: 'Eco',
              temp: 19.0,
              icon: '🌱',
              isSelected: (state.targetTemp - 19.0).abs() < 0.2,
            ),
            const SizedBox(width: 8),
            _buildModePill(
              title: 'Konfor',
              temp: 22.0,
              icon: '🛋️',
              isSelected: (state.targetTemp - 22.0).abs() < 0.2,
            ),
            const SizedBox(width: 8),
            _buildModePill(
              title: 'Gece',
              temp: 20.5,
              icon: '🌙',
              isSelected: (state.targetTemp - 20.5).abs() < 0.2,
            ),
            const SizedBox(width: 8),
            _buildModePill(
              title: 'Boost',
              temp: 25.0,
              icon: '⚡',
              isSelected: (state.targetTemp - 25.0).abs() < 0.2,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 2. Kombi Canlı Telemetrisi Kartı
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Text('🔥', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Text(
                        'Kombi Telemetrisi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onToggleRelay();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: state.isRelayActive
                            ? AppTheme.flameOrange.withOpacity(0.2)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: state.isRelayActive
                              ? AppTheme.flameOrange
                              : AppTheme.textMuted,
                        ),
                      ),
                      child: Text(
                        state.isRelayActive ? 'Röle: AÇIK' : 'Röle: KAPALI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: state.isRelayActive ? AppTheme.flameOrange : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Alev Modülasyonu Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Alev Modülasyonu',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  Text(
                    '%${state.flameModulation}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.flameAmber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (state.flameModulation / 100).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: const Color(0xFF1B2436),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.flameOrange),
                ),
              ),
              const SizedBox(height: 16),

              // 2'li Izgara: Su Basıncı & Nem
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      icon: '💧',
                      label: 'Su Basıncı',
                      value: '${state.waterPressure.toStringAsFixed(1)} Bar',
                      status: 'Optimal (1.5)',
                      color: AppTheme.cyanCool,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      icon: '💨',
                      label: 'Oda Nemi',
                      value: '%${state.humidity.toStringAsFixed(0)}',
                      status: 'İdeal Konfor',
                      color: AppTheme.greenEco,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModePill({
    required String title,
    required double temp,
    required String icon,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onSetPreset(temp);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.flameOrange.withOpacity(0.2) : AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.flameOrange : AppTheme.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                ),
              ),
              Text(
                '${temp.toStringAsFixed(0)}°C',
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? AppTheme.flameAmber : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String icon,
    required String label,
    required String value,
    required String status,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            status,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
