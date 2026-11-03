import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/heatmap_matrix_widget.dart';
import '../widgets/comfort_index_widget.dart';
import '../services/history_storage_service.dart';

class TelemetryHourData {
  final String hourLabel;
  final double temp;
  final double target;
  final bool isKombiActive;
  final int flamePercent;
  final double gasM3;

  const TelemetryHourData({
    required this.hourLabel,
    required this.temp,
    required this.target,
    required this.isKombiActive,
    required this.flamePercent,
    required this.gasM3,
  });
}

class ReportsScreen extends StatefulWidget {
  final double currentTemp;
  final double targetTemp;
  final double humidity;
  final double waterPressure;
  final bool isHeating;
  final int flamePercent;

  const ReportsScreen({
    super.key,
    this.currentTemp = 21.8,
    this.targetTemp = 22.5,
    this.humidity = 48.0,
    this.waterPressure = 1.6,
    this.isHeating = true,
    this.flamePercent = 68,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _activeLayer = 0; // 0: Sıcaklık Haritası, 1: Fatura & Tüketim, 2: Kombi Sensörleri
  String _timeframe = 'daily'; // 'daily' | 'weekly' | 'monthly'
  double _gasUnitPrice = 10.25; // ₺/m³
  TelemetryHourData? _selectedHour;
  bool _show168Matrix = true; // 168-cell matrix or 24-h curve

  @override
  void initState() {
    super.initState();
    _loadGasPrice();
  }

  Future<void> _loadGasPrice() async {
    final price = await HistoryStorageService().getGasUnitPrice();
    if (mounted) {
      setState(() => _gasUnitPrice = price);
    }
  }

  final List<TelemetryHourData> _hourlyTelemetry = const [
    TelemetryHourData(hourLabel: '00:00', temp: 20.2, target: 19.5, isKombiActive: false, flamePercent: 0, gasM3: 0.0),
    TelemetryHourData(hourLabel: '02:00', temp: 19.6, target: 19.5, isKombiActive: false, flamePercent: 0, gasM3: 0.0),
    TelemetryHourData(hourLabel: '04:00', temp: 19.2, target: 19.5, isKombiActive: true, flamePercent: 45, gasM3: 0.15),
    TelemetryHourData(hourLabel: '06:00', temp: 19.8, target: 22.0, isKombiActive: true, flamePercent: 85, gasM3: 0.38),
    TelemetryHourData(hourLabel: '08:00', temp: 21.7, target: 22.0, isKombiActive: true, flamePercent: 60, gasM3: 0.28),
    TelemetryHourData(hourLabel: '10:00', temp: 22.1, target: 21.5, isKombiActive: false, flamePercent: 0, gasM3: 0.0),
    TelemetryHourData(hourLabel: '12:00', temp: 22.0, target: 21.5, isKombiActive: false, flamePercent: 0, gasM3: 0.0),
    TelemetryHourData(hourLabel: '14:00', temp: 22.4, target: 21.5, isKombiActive: false, flamePercent: 0, gasM3: 0.0),
    TelemetryHourData(hourLabel: '16:00', temp: 21.9, target: 22.0, isKombiActive: true, flamePercent: 55, gasM3: 0.22),
    TelemetryHourData(hourLabel: '18:00', temp: 22.3, target: 22.5, isKombiActive: true, flamePercent: 70, gasM3: 0.32),
    TelemetryHourData(hourLabel: '20:00', temp: 22.6, target: 22.5, isKombiActive: false, flamePercent: 0, gasM3: 0.0),
    TelemetryHourData(hourLabel: '22:00', temp: 22.1, target: 21.0, isKombiActive: false, flamePercent: 0, gasM3: 0.0),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          // ── ÜST 3'LÜ KATMAN SEÇİCİ KAPSÜL ──
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
                _buildLayerPill(0, '🌡️ Sıcaklık', 'Canlı Eğri'),
                _buildLayerPill(1, '💰 Fatura', 'Gaz Tüketimi'),
                _buildLayerPill(2, '🔥 Sensörler', 'Basınç & Devir'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── SEÇİLİ KATMAN İÇERİĞİ ──
          if (_activeLayer == 0)
            _buildHeatmapLayer()
          else if (_activeLayer == 1)
            _buildBillLayer()
          else
            _buildSensorsLayer(),
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
          setState(() {
            _activeLayer = index;
            _selectedHour = null;
          });
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
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
              ),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 8.5,
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

  // ── KATMAN 0: SICAKLIK HARİTASI & CANLI EĞRİ ──
  Widget _buildHeatmapLayer() {
    return Column(
      children: [
        // Görünüm Modu Seçici (168 Hücre Matris vs 24s Spline Trend)
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFF14121E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _show168Matrix = true);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: _show168Matrix ? const Color(0xFFFF8C32) : Colors.transparent,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: _show168Matrix
                          ? [BoxShadow(color: const Color(0xFFFF8C32).withOpacity(0.35), blurRadius: 8)]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '🗓️ 168 Hücre Matrisi (7x24)',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: _show168Matrix ? Colors.white : Colors.white60,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _show168Matrix = false);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: !_show168Matrix ? const Color(0xFF38BDF8) : Colors.transparent,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: !_show168Matrix
                          ? [BoxShadow(color: const Color(0xFF38BDF8).withOpacity(0.35), blurRadius: 8)]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '📈 24s Trend Eğrisi',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: !_show168Matrix ? Colors.white : Colors.white60,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (_show168Matrix)
          HeatmapMatrixWidget(gasUnitPrice: _gasUnitPrice)
        else ...[
          // Zaman Aralığı Butonları (Günlük, Haftalık, Aylık)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeframeBtn('daily', 'Günlük'),
              const SizedBox(width: 8),
              _buildTimeframeBtn('weekly', 'Haftalık'),
              const SizedBox(width: 8),
              _buildTimeframeBtn('monthly', 'Aylık'),
            ],
          ),
          const SizedBox(height: 12),

          // 24 Saatlik Canlı Grafiği Taşıyan Kart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B29),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
              boxShadow: const [
                BoxShadow(color: Color(0xFF0C0B10), offset: Offset(0, 4), blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '24 Saatlik Sıcaklık Trendi',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    Text(
                      'Ort. 21.6°C',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF38BDF8), fontFamily: 'monospace'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Canvas Çizimi
                GestureDetector(
                  onTapUp: (details) {
                    final renderBox = context.findRenderObject() as RenderBox?;
                    if (renderBox != null) {
                      final width = 280.0;
                      final clickX = details.localPosition.dx.clamp(0.0, width);
                      final fraction = clickX / width;
                      final index = (fraction * (_hourlyTelemetry.length - 1)).round().clamp(0, _hourlyTelemetry.length - 1);
                      HapticFeedback.selectionClick();
                      setState(() => _selectedHour = _hourlyTelemetry[index]);
                    }
                  },
                  child: SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _SmoothSplinePainter(data: _hourlyTelemetry),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // X Ekseni Saat Etiketleri
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('00:00', style: TextStyle(fontSize: 9, color: Colors.white38)),
                    Text('06:00', style: TextStyle(fontSize: 9, color: Colors.white38)),
                    Text('12:00', style: TextStyle(fontSize: 9, color: Colors.white38)),
                    Text('18:00', style: TextStyle(fontSize: 9, color: Colors.white38)),
                    Text('23:59', style: TextStyle(fontSize: 9, color: Colors.white38)),
                  ],
                ),
              ],
            ),
          ),

          // Seçilen Saat Detay Pop-Up'ı
          if (_selectedHour != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF282536),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF8C32).withOpacity(0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, color: Color(0xFFFFB800), size: 16),
                      const SizedBox(width: 6),
                      Text('${_selectedHour!.hourLabel}: ', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('${_selectedHour!.temp.toStringAsFixed(1)}°C', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text(
                    _selectedHour!.isKombiActive ? '🔥 Kombi Aktif (%${_selectedHour!.flamePercent})' : '❄️ Kombi Kapalı',
                    style: TextStyle(
                      color: _selectedHour!.isKombiActive ? const Color(0xFFFF8C32) : Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildTimeframeBtn(String id, String label) {
    final isSel = _timeframe == id;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _timeframe = id);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFFF8C32) : const Color(0xFF1E1B29),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSel ? const Color(0xFFFFB800) : Colors.white12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSel ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }

  // ── KATMAN 1: DOĞALGAZ FATURASI & TÜKETİM ──
  Widget _buildBillLayer() {
    const totalGasM3 = 3.45; // m³
    final billTotal = totalGasM3 * _gasUnitPrice;
    final unmodulatedTotal = (totalGasM3 * 1.28) * _gasUnitPrice;
    final savedNet = unmodulatedTotal - billTotal;

    return Column(
      children: [
        // Gaz Birim Fiyatı Düzenleme Barı
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B29),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: Color(0xFFFFB800), size: 18),
                  SizedBox(width: 8),
                  Text('Doğalgaz Birim Fiyatı:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _gasUnitPrice = math.max(1.0, _gasUnitPrice - 0.25));
                      HistoryStorageService().setGasUnitPrice(_gasUnitPrice);
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6)),
                      child: const Center(child: Text('-', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${_gasUnitPrice.toStringAsFixed(2)} ₺/m³',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace'),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _gasUnitPrice += 0.25);
                      HistoryStorageService().setGasUnitPrice(_gasUnitPrice);
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6)),
                      child: const Center(child: Text('+', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Tahmini Fatura Kartı
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E241E), Color(0xFF1E1B29)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFFF8C32).withOpacity(0.35)),
            boxShadow: const [
              BoxShadow(color: Color(0xFF0C0B10), offset: Offset(0, 4), blurRadius: 10),
            ],
          ),
          child: Column(
            children: [
              const Text('BUGÜNKÜ TAHMİNİ DOĞALGAZ TUTARI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
              const SizedBox(height: 8),
              Text(
                '${billTotal.toStringAsFixed(2)} ₺',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFFFFB800), fontFamily: 'monospace'),
              ),
              const SizedBox(height: 4),
              Text('Toplam Tüketim: ${totalGasM3.toStringAsFixed(2)} m³ gaz', style: const TextStyle(fontSize: 11, color: Colors.white60)),
              const Divider(color: Colors.white12, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Kombisiz/Klasik', style: TextStyle(fontSize: 10, color: Colors.white38)),
                      Text('${unmodulatedTotal.toStringAsFixed(1)} ₺', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white60)),
                    ],
                  ),
                  Container(width: 1, height: 24, color: Colors.white12),
                  Column(
                    children: [
                      const Text('Net Cepte Kalan', style: TextStyle(fontSize: 10, color: Color(0xFFA7F3D0))),
                      Text('+${savedNet.toStringAsFixed(1)} ₺ (%28)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── KATMAN 2: KOMBİ SENSÖRLERİ & TELEMETRİ ──
  Widget _buildSensorsLayer() {
    return Column(
      children: [
        ComfortIndexWidget(
          currentTemp: widget.currentTemp,
          humidity: widget.humidity,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSensorTile(
                title: 'SU BASINCI',
                value: '${widget.waterPressure.toStringAsFixed(1)} Bar',
                status: 'İdeal (1.2 - 2.0)',
                icon: Icons.speed_rounded,
                color: const Color(0xFF38BDF8),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSensorTile(
                title: 'POMPA DEVRİ',
                value: widget.isHeating ? '1420 RPM' : '0 RPM',
                status: widget.isHeating ? 'Sirkülasyon Aktif' : 'Beklemede',
                icon: Icons.sync_rounded,
                color: const Color(0xFFA855F7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSensorTile(
                title: 'BAĞIL NEM',
                value: '%${widget.humidity.toInt()}',
                status: 'Konfor Aralığı',
                icon: Icons.water_drop_rounded,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSensorTile(
                title: 'ALEV MODÜLASYONU',
                value: widget.isHeating ? '%${widget.flamePercent}' : '%0',
                status: widget.isHeating ? 'Ateşleme Açık' : 'Kapalı',
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFFF8C32),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSensorTile({
    required String title,
    required String value,
    required String status,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B29),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(color: Color(0xFF0C0B10), offset: Offset(0, 3), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'monospace')),
          const SizedBox(height: 2),
          Text(status, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// 24 Saatlik Sıcaklık Spline Çizgi Çizicisi
class _SmoothSplinePainter extends CustomPainter {
  final List<TelemetryHourData> data;

  _SmoothSplinePainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final minTemp = 18.0;
    final maxTemp = 24.0;
    final stepX = size.width / (data.length - 1);

    final linePath = Path();
    final fillPath = Path();

    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedY = (data[i].temp - minTemp) / (maxTemp - minTemp);
      final y = size.height - (normalizedY.clamp(0.0, 1.0) * size.height);
      points.add(Offset(x, y));
    }

    linePath.moveTo(points.first.dx, points.first.dy);
    fillPath.moveTo(points.first.dx, size.height);
    fillPath.lineTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
      fillPath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    // Gradyan Alt Dolgusu
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF38BDF8).withOpacity(0.35),
          const Color(0xFF38BDF8).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Çizgi Çizimi
    final linePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // Noktalar ve Alev İndikatörleri
    final dotPaint = Paint()..color = Colors.white;
    final flamePaint = Paint()..color = const Color(0xFFFF8C32);

    for (int i = 0; i < points.length; i++) {
      if (data[i].isKombiActive) {
        canvas.drawCircle(points[i], 4.5, flamePaint);
      }
      canvas.drawCircle(points[i], 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
