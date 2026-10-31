import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class ScheduleItem {
  String id;
  String name;
  String time;
  double targetTemp;
  bool isEnabled;

  ScheduleItem({
    required this.id,
    required this.name,
    required this.time,
    required this.targetTemp,
    required this.isEnabled,
  });
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final List<ScheduleItem> _schedules = [
    ScheduleItem(id: '1', name: '🌙 Gece Modu', time: '23:00', targetTemp: 19.5, isEnabled: true),
    ScheduleItem(id: '2', name: '☀️ Sabah Uyanış', time: '06:30', targetTemp: 22.5, isEnabled: true),
    ScheduleItem(id: '3', name: '🏢 Dışarıda / Tasarruf', time: '08:30', targetTemp: 18.0, isEnabled: false),
    ScheduleItem(id: '4', name: '🛋️ Akşam Konforu', time: '18:00', targetTemp: 23.0, isEnabled: true),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Otomatik Zaman Programı',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // New program dialog
                },
                icon: const Icon(Icons.add_circle, color: AppTheme.flameOrange, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ..._schedules.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: item.isEnabled ? AppTheme.surface : AppTheme.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: item.isEnabled ? AppTheme.border : Colors.white10,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: item.isEnabled
                            ? AppTheme.flameOrange.withOpacity(0.15)
                            : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.time,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: item.isEnabled ? AppTheme.flameOrange : AppTheme.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: item.isEnabled ? AppTheme.textPrimary : AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            'Hedef: ${item.targetTemp}°C',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.flameAmber,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: item.isEnabled,
                      activeColor: AppTheme.flameOrange,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          item.isEnabled = val;
                        });
                      },
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
