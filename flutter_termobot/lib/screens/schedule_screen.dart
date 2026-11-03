import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class ScheduleItem {
  String id;
  String name;
  String time;
  double targetTemp;
  bool isEnabled;
  String icon;

  ScheduleItem({
    required this.id,
    required this.name,
    required this.time,
    required this.targetTemp,
    required this.isEnabled,
    this.icon = '⏰',
  });

  ScheduleItem copyWith({
    String? id,
    String? name,
    String? time,
    double? targetTemp,
    bool? isEnabled,
    String? icon,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      name: name ?? this.name,
      time: time ?? this.time,
      targetTemp: targetTemp ?? this.targetTemp,
      isEnabled: isEnabled ?? this.isEnabled,
      icon: icon ?? this.icon,
    );
  }
}

class ScheduleScreen extends StatefulWidget {
  final int dailyRunMinutes;
  final int flamePercent;

  const ScheduleScreen({
    super.key,
    this.dailyRunMinutes = 145,
    this.flamePercent = 68,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _activeLayer = 0; // 0: Akıllı Zaman Programı, 1: Günlük Tüketim & Tasarruf
  int _selectedDayIndex = 0; // 0: Pzt, 1: Sal, ... 6: Paz
  bool _saveSuccess = false;

  final List<String> _days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  List<ScheduleItem> _schedules = [
    ScheduleItem(id: '1', name: 'Gece Modu', time: '23:00', targetTemp: 18.5, isEnabled: true, icon: '🌙'),
    ScheduleItem(id: '2', name: 'Sabah Uyanış', time: '06:30', targetTemp: 22.5, isEnabled: true, icon: '☀️'),
    ScheduleItem(id: '3', name: 'Dışarıda / Tasarruf', time: '08:30', targetTemp: 17.5, isEnabled: false, icon: '🏢'),
    ScheduleItem(id: '4', name: 'Akşam Konforu', time: '18:00', targetTemp: 22.0, isEnabled: true, icon: '🛋️'),
  ];

  void _toggleItem(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _schedules[index] = _schedules[index].copyWith(isEnabled: !_schedules[index].isEnabled);
    });
  }

  void _updateTemp(int index, double delta) {
    HapticFeedback.selectionClick();
    setState(() {
      final next = (_schedules[index].targetTemp + delta).clamp(16.0, 30.0);
      _schedules[index] = _schedules[index].copyWith(targetTemp: (next * 2).round() / 2.0);
    });
  }

  void _saveSchedules() {
    HapticFeedback.mediumImpact();
    setState(() => _saveSuccess = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saveSuccess = false);
    });
  }

  void _addNewProgramDialog() {
    String name = 'Özel Program';
    String time = '12:00';
    double temp = 21.0;
    String icon = '⭐';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF1B1926),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Colors.white24),
          ),
          title: const Row(
            children: [
              Icon(Icons.add_alarm_rounded, color: Color(0xFFFF8C32)),
              SizedBox(width: 8),
              Text('Yeni Zaman Programı', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Program Adı',
                  labelStyle: TextStyle(color: Colors.white60),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (v) => name = v,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Saat:', style: TextStyle(color: Colors.white70)),
                  DropdownButton<String>(
                    dropdownColor: const Color(0xFF1B1926),
                    value: time,
                    items: List.generate(24, (h) {
                      final str = '${h.toString().padLeft(2, '0')}:00';
                      return DropdownMenuItem(value: str, child: Text(str, style: const TextStyle(color: Colors.white)));
                    }),
                    onChanged: (v) => setDlgState(() => time = v!),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Hedef Sıcaklık:', style: TextStyle(color: Colors.white70)),
                  Text('${temp.toStringAsFixed(1)}°C', style: const TextStyle(color: Color(0xFFFF8C32), fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: temp,
                min: 16.0,
                max: 30.0,
                divisions: 28,
                activeColor: const Color(0xFFFF8C32),
                onChanged: (v) => setDlgState(() => temp = (v * 2).round() / 2.0),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C32)),
              onPressed: () {
                setState(() {
                  _schedules.add(ScheduleItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    time: time,
                    targetTemp: temp,
                    isEnabled: true,
                    icon: icon,
                  ));
                });
                Navigator.pop(ctx);
              },
              child: const Text('Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          // ── KATMAN SEÇİCİ KAPSÜL (Zaman Programı / Tüketim & Tasarruf) ──
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF14121E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
              boxShadow: const [
                BoxShadow(color: Color(0xFF0C0B10), offset: Offset(0, 3), blurRadius: 4),
              ],
            ),
            child: Row(
              children: [
                _buildLayerPill(0, '⏰ Akıllı Zamanlama', 'Haftalık Program'),
                _buildLayerPill(1, '⚡ Tüketim & Tasarruf', 'Kombi Harcaması'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── KATMAN GÖVDELERİ ──
          if (_activeLayer == 0) _buildScheduleTab() else _buildConsumptionTab(),
        ],
      ),
    );
  }

  Widget _buildLayerPill(int index, String title, String sub) {
    final isSelected = _activeLayer == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _activeLayer = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF282536) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isSelected ? Border.all(color: const Color(0xFFFF8C32).withOpacity(0.5)) : null,
            boxShadow: isSelected
                ? [
                    const BoxShadow(color: Color(0xFF0C0B10), offset: Offset(0, 2), blurRadius: 4),
                    BoxShadow(color: const Color(0xFFFF8C32).withOpacity(0.2), blurRadius: 8),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
              ),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? const Color(0xFFFFB800) : Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleTab() {
    return Column(
      children: [
        // Hafta Günleri Seçici Barı
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF161422),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_days.length, (idx) {
              final isDaySelected = _selectedDayIndex == idx;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedDayIndex = idx);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDaySelected ? const Color(0xFFFF8C32) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isDaySelected
                        ? [
                            BoxShadow(color: const Color(0xFFFF8C32).withOpacity(0.6), blurRadius: 8),
                          ]
                        : null,
                  ),
                  child: Text(
                    _days[idx],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: isDaySelected ? Colors.white : Colors.white60,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),

        // Program Satırları Listesi
        ...List.generate(_schedules.length, (index) {
          final item = _schedules[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item.isEnabled ? const Color(0xFF221F2E) : const Color(0xFF181622),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: item.isEnabled ? Colors.white.withOpacity(0.18) : Colors.white.withOpacity(0.06),
              ),
              boxShadow: const [
                BoxShadow(color: Color(0xFF0C0B10), offset: Offset(0, 3), blurRadius: 4),
              ],
            ),
            child: Row(
              children: [
                // İkon & Saat
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14121E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(item.icon, style: const TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 10),

                // İsim & Saat Bilgisi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: item.isEnabled ? Colors.white : Colors.white38,
                        ),
                      ),
                      Text(
                        item.time,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          color: item.isEnabled ? const Color(0xFFFFB800) : Colors.white24,
                        ),
                      ),
                    ],
                  ),
                ),

                // Hedef Derece Stepper
                if (item.isEnabled) ...[
                  GestureDetector(
                    onTap: () => _updateTemp(index, -0.5),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E2A3C),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Center(child: Text('-', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${item.targetTemp.toStringAsFixed(1)}°',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        color: Colors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _updateTemp(index, 0.5),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E2A3C),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Center(child: Text('+', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],

                // Aktiflik Switch'i
                Switch(
                  value: item.isEnabled,
                  activeColor: const Color(0xFFFF8C32),
                  activeTrackColor: const Color(0xFFFF8C32).withOpacity(0.4),
                  inactiveThumbColor: Colors.white38,
                  inactiveTrackColor: Colors.black26,
                  onChanged: (_) => _toggleItem(index),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 10),

        // Alt Eylem Butonları (Yeni Ekle & Kaydet)
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF221F2E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Yeni Ekle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: _addNewProgramDialog,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _saveSuccess ? const Color(0xFF10B981) : const Color(0xFFFF8C32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                ),
                icon: Icon(_saveSuccess ? Icons.check_circle_rounded : Icons.save_rounded, size: 18),
                label: Text(
                  _saveSuccess ? 'Kaydedildi!' : 'Kaydet',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: _saveSchedules,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConsumptionTab() {
    final hours = widget.dailyRunMinutes ~/ 60;
    final mins = widget.dailyRunMinutes % 60;
    // 24kW boiler at modulated flame consumes ~1.8 m3/h at max flame
    final m3Gas = (widget.dailyRunMinutes / 60) * 1.8 * (widget.flamePercent / 100);
    const gasUnitPrice = 10.25; // TL / m3
    final estimatedCost = m3Gas * gasUnitPrice;
    final unmodulatedCost = (m3Gas * 1.28) * gasUnitPrice;
    final savedTL = (unmodulatedCost - estimatedCost).clamp(0.0, 9999.0);

    return Column(
      children: [
        // Günlük Çalışma Süresi Kartı
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF221F2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
            boxShadow: const [
              BoxShadow(color: Color(0xFF0C0B10), offset: Offset(0, 4), blurRadius: 8),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4)),
                ),
                child: const Center(
                  child: Icon(Icons.timer_rounded, color: Color(0xFF60A5FA), size: 24),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BUGÜN ATEŞLEME SÜRESİ',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.0),
                    ),
                    Text(
                      '$hours saat $mins dakika',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: const Text('Normal', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Tahmini Gaz & Fatura Tutarı İkili Kart
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1826),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DOĞALGAZ (m³)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 4),
                    Text('${m3Gas.toStringAsFixed(2)} m³', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'monospace')),
                    const SizedBox(height: 2),
                    const Text('Birim: 10.25 ₺/m³', style: TextStyle(fontSize: 9, color: Colors.white38)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1826),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BUGÜNKÜ FATURA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 4),
                    Text('${estimatedCost.toStringAsFixed(1)} ₺', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFFFB800), fontFamily: 'monospace')),
                    const SizedBox(height: 2),
                    const Text('Tahmini Tutar', style: TextStyle(fontSize: 9, color: Colors.white38)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Akıllı Modülasyon Tasarruf Banner'ı
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF064E3B), Color(0xFF047857)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.eco_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '0.4°C HİSTEREZİS TASARRUFU',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFA7F3D0), letterSpacing: 0.8),
                    ),
                    Text(
                      'Bugün +${savedTL.toStringAsFixed(1)} ₺ tasarruf edildi',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const Text(
                      'Klasik aç/kapa termostatlara göre %28 daha verimli',
                      style: TextStyle(fontSize: 9, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
