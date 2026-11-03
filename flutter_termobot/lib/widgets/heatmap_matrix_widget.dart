import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/history_storage_service.dart';

class HeatmapHourData {
  final int hour; // 0 - 23
  final double temp;
  final double target;
  final bool isHeating;
  final int flamePercent;
  final double gasM3;

  const HeatmapHourData({
    required this.hour,
    required this.temp,
    required this.target,
    required this.isHeating,
    required this.flamePercent,
    required this.gasM3,
  });
}

class HeatmapDayRecord {
  final String dateKey;
  final String dateTitle;
  final String dayName;
  final double avgTemp;
  final int totalActiveMinutes;
  final double totalGasM3;
  final List<HeatmapHourData> hours;

  const HeatmapDayRecord({
    required this.dateKey,
    required this.dateTitle,
    required this.dayName,
    required this.avgTemp,
    required this.totalActiveMinutes,
    required this.totalGasM3,
    required this.hours,
  });
}

class HeatmapMatrixWidget extends StatefulWidget {
  final double gasUnitPrice;

  const HeatmapMatrixWidget({
    super.key,
    this.gasUnitPrice = 10.45,
  });

  @override
  State<HeatmapMatrixWidget> createState() => _HeatmapMatrixWidgetState();
}

class _HeatmapMatrixWidgetState extends State<HeatmapMatrixWidget> {
  int _selectedDayIdx = 0; // 0 to 6
  HeatmapHourData? _tappedCell;
  String _tappedDayTitle = '';
  bool _isWeeklyGridView = true; // true: 7x24 168-cell matrix, false: selected day 24-cells

  late List<HeatmapDayRecord> _weekData;

  @override
  void initState() {
    super.initState();
    _initHistoricalDatabase();
    _loadFromPersistence();
  }

  Future<void> _loadFromPersistence() async {
    try {
      final loaded = await HistoryStorageService().loadHistoricalWeek();
      if (mounted && loaded.isNotEmpty) {
        setState(() {
          _weekData = loaded;
        });
      }
    } catch (_) {}
  }

  void _initHistoricalDatabase() {
    final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final titles = [
      'Pazartesi (12 Eki)',
      'Salı (13 Eki)',
      'Çarşamba (14 Eki)',
      'Perşembe (15 Eki)',
      'Cuma (16 Eki)',
      'Cumartesi (17 Eki)',
      'Pazar (Bugün)',
    ];

    // Build 7 days x 24 hours = 168 cells with realistic heating patterns
    _weekData = List.generate(7, (dayIdx) {
      final hours = List.generate(24, (h) {
        // Night cooler, morning warm up, evening comfort
        double baseTemp = 19.0;
        bool heating = false;
        int flame = 0;
        double gas = 0.0;

        if (h >= 0 && h < 6) {
          baseTemp = 18.2 + (dayIdx * 0.1) + (h * 0.1);
          if (h == 3 || h == 4) {
            heating = true;
            flame = 35;
            gas = 0.18;
          }
        } else if (h >= 6 && h < 9) {
          baseTemp = 20.5 + (h - 6) * 0.7;
          heating = true;
          flame = 80;
          gas = 0.45;
        } else if (h >= 9 && h < 17) {
          baseTemp = 21.8 + ((h % 3) * 0.2);
          heating = (h == 12 || h == 15);
          flame = heating ? 40 : 0;
          gas = heating ? 0.22 : 0.0;
        } else if (h >= 17 && h < 22) {
          baseTemp = 22.4 + ((h % 2) * 0.3);
          heating = true;
          flame = 65;
          gas = 0.38;
        } else {
          baseTemp = 21.0 - ((h - 22) * 0.5);
          heating = false;
        }

        return HeatmapHourData(
          hour: h,
          temp: (baseTemp * 10).round() / 10.0,
          target: heating ? 22.5 : 19.5,
          isHeating: heating,
          flamePercent: flame,
          gasM3: gas,
        );
      });

      final activeMin = hours.where((h) => h.isHeating).length * 42;
      final totalGas = hours.fold(0.0, (acc, h) => acc + h.gasM3);
      final avgTemp = hours.fold(0.0, (acc, h) => acc + h.temp) / 24.0;

      return HeatmapDayRecord(
        dateKey: '2026-10-${12 + dayIdx}',
        dateTitle: titles[dayIdx],
        dayName: days[dayIdx],
        avgTemp: (avgTemp * 10).round() / 10.0,
        totalActiveMinutes: activeMin,
        totalGasM3: (totalGas * 100).round() / 100.0,
        hours: hours,
      );
    });
  }

  Color _getTempColor(double temp) {
    if (temp < 18.5) return const Color(0xFF0284C7); // Mavi
    if (temp < 20.0) return const Color(0xFF0D9488); // Teal
    if (temp < 21.5) return const Color(0xFF10B981); // Zümrüt Yeşil
    if (temp < 23.0) return const Color(0xFFF59E0B); // Amber Sıcak
    return const Color(0xFFEA580C); // Turuncu / Sıcak
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF171522),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: const [
          BoxShadow(color: Color(0xFF0C0B10), offset: Offset(0, 4), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── ÜST BAŞLIK & GÖRÜNÜM GEÇİŞ BUTONU ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.grid_on_rounded, color: Color(0xFFFF8C32), size: 18),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '168 Hücreli Sıcaklık Isı Haritası',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      Text(
                        _isWeeklyGridView ? '7 Gün × 24 Saatlik Sıcaklık & Brülör Matrisi' : 'Seçili Günün 24 Saatlik Dağılımı',
                        style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _isWeeklyGridView = !_isWeeklyGridView);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242033),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFF8C32).withOpacity(0.4)),
                  ),
                  child: Text(
                    _isWeeklyGridView ? '24S Günlük' : '7×24 Matris',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF8C32)),
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 20),

          // ── GÜN SEÇİCİ ÇİPLER (7 GÜN) ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(_weekData.length, (idx) {
                final d = _weekData[idx];
                final isSel = _selectedDayIdx == idx;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedDayIdx = idx;
                        _tappedCell = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFFFF8C32) : const Color(0xFF221F2E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel ? const Color(0xFFFFB800) : Colors.white12,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            d.dayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSel ? Colors.white : Colors.white70,
                            ),
                          ),
                          Text(
                            '${d.avgTemp}°',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              color: isSel ? Colors.white : const Color(0xFF38BDF8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),

          // ── 168 HÜCRELİ 7×24 MATRİS GÖRÜNÜMÜ ──
          if (_isWeeklyGridView) ...[
            _build168WeeklyMatrix(),
          ] else ...[
            // SEÇİLİ GÜNÜN 24 SAATLİK IZGARASI
            _buildDaily24Grid(_weekData[_selectedDayIdx]),
          ],

          const SizedBox(height: 10),

          // ── DOKUNULAN HÜCRE ANLIK TELEMETRİ KARTI ──
          if (_tappedCell != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF252136),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF8C32).withOpacity(0.6)),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF0C0B10), offset: Offset(0, 3), blurRadius: 6),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, color: Color(0xFFFFB800), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '$_tappedDayTitle ${(_tappedCell!.hour).toString().padLeft(2, '0')}:00',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Oda: ${_tappedCell!.temp}°C • Hedef: ${_tappedCell!.target}°C',
                        style: const TextStyle(fontSize: 10.5, color: Colors.white70),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _tappedCell!.isHeating ? '🔥 Brülör Aktif (%${_tappedCell!.flamePercent})' : '❄️ Beklemede',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: _tappedCell!.isHeating ? const Color(0xFFFF8C32) : const Color(0xFF60A5FA),
                        ),
                      ),
                      Text(
                        _tappedCell!.gasM3 > 0
                            ? '${_tappedCell!.gasM3} m³ (~${(_tappedCell!.gasM3 * widget.gasUnitPrice).toStringAsFixed(2)} ₺)'
                            : '0.00 m³ (0 ₺)',
                        style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.white60),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // ── RENK SKALASI AÇIKLAMA BARI ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegend(const Color(0xFF0284C7), '< 18.5°'),
              _buildLegend(const Color(0xFF0D9488), '19° - 20°'),
              _buildLegend(const Color(0xFF10B981), '20° - 21.5°'),
              _buildLegend(const Color(0xFFF59E0B), '21.5° - 23°'),
              _buildLegend(const Color(0xFFEA580C), '23°+'),
            ],
          ),
        ],
      ),
    );
  }

  // 168 Hücreli 7 Gün × 24 Saatlik Canlı Matris Çizimi
  Widget _build168WeeklyMatrix() {
    return Column(
      children: [
        // Saat başlıkları (00, 04, 08, 12, 16, 20, 23)
        Padding(
          padding: const EdgeInsets.only(left: 32, bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('00', style: TextStyle(fontSize: 8, color: Colors.white38)),
              Text('04', style: TextStyle(fontSize: 8, color: Colors.white38)),
              Text('08', style: TextStyle(fontSize: 8, color: Colors.white38)),
              Text('12', style: TextStyle(fontSize: 8, color: Colors.white38)),
              Text('16', style: TextStyle(fontSize: 8, color: Colors.white38)),
              Text('20', style: TextStyle(fontSize: 8, color: Colors.white38)),
              Text('23', style: TextStyle(fontSize: 8, color: Colors.white38)),
            ],
          ),
        ),

        // 7 Gün Satırları (Her satırda 24 hücre = 168 Hücre)
        ...List.generate(7, (dIdx) {
          final day = _weekData[dIdx];
          return Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: [
                // Gün Adı Etiketi
                SizedBox(
                  width: 28,
                  child: Text(
                    day.dayName,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: _selectedDayIdx == dIdx ? const Color(0xFFFF8C32) : Colors.white60,
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // 24 Saatlik Hücreler
                Expanded(
                  child: Row(
                    children: List.generate(24, (hIdx) {
                      final h = day.hours[hIdx];
                      final cellColor = _getTempColor(h.temp);
                      final isSelected = _tappedCell == h;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _tappedCell = h;
                              _tappedDayTitle = day.dateTitle;
                              _selectedDayIdx = dIdx;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 0.5),
                            height: 18,
                            decoration: BoxDecoration(
                              color: cellColor.withOpacity(h.isHeating ? 0.95 : 0.45),
                              borderRadius: BorderRadius.circular(3),
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 1.5)
                                  : (h.isHeating ? Border.all(color: const Color(0xFFFF9900), width: 0.8) : null),
                            ),
                            child: h.isHeating
                                ? const Center(
                                    child: Icon(Icons.circle, color: Colors.white, size: 3),
                                  )
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Seçili Günün 24 Saatlik Izgara Kartları
  Widget _buildDaily24Grid(HeatmapDayRecord day) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${day.dateTitle} • Toplam: ${day.totalGasM3} m³ (${(day.totalGasM3 * widget.gasUnitPrice).toStringAsFixed(1)} ₺)',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFFB800)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: day.hours.map((h) {
            final color = _getTempColor(h.temp);
            final isSel = _tappedCell == h;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _tappedCell = h;
                  _tappedDayTitle = day.dateTitle;
                });
              },
              child: Container(
                width: 44,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(h.isHeating ? 0.9 : 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSel ? Colors.white : (h.isHeating ? const Color(0xFFFF9900) : Colors.white12),
                    width: isSel ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${h.hour.toString().padLeft(2, '0')}:00',
                      style: const TextStyle(fontSize: 8, color: Colors.white70, fontFamily: 'monospace'),
                    ),
                    Text(
                      '${h.temp}°',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace'),
                    ),
                    if (h.isHeating)
                      const Icon(Icons.local_fire_department, size: 10, color: Colors.white),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLegend(Color c, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 9, color: Colors.white54)),
      ],
    );
  }
}
