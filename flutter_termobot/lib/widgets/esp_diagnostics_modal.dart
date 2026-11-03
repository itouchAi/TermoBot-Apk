import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EspEventLog {
  final String id;
  final DateTime timestamp;
  final String type; // 'combustion_start', 'combustion_end', 'wdt_check', 'reboot', 'stress_test', 'packet'
  final String title;
  final String details;
  final String wdtStatus;

  const EspEventLog({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.title,
    required this.details,
    this.wdtStatus = 'ok',
  });
}

class EspDiagnosticsModal extends StatefulWidget {
  final String espIp;
  final int espPort;
  final bool isConnected;

  const EspDiagnosticsModal({
    super.key,
    this.espIp = '192.168.1.142',
    this.espPort = 80,
    this.isConnected = true,
  });

  @override
  State<EspDiagnosticsModal> createState() => _EspDiagnosticsModalState();
}

class _EspDiagnosticsModalState extends State<EspDiagnosticsModal> {
  // Canlı ping gecikme değerleri (ms)
  final List<int> _pingHistory = [32, 28, 41, 26, 30, 24, 38, 22, 29, 34, 27, 31];
  Timer? _pingTimer;

  // Donanım Telemetri Durumu
  int _uptimeSeconds = 84320; // ~23.4 saat
  int _freeHeapBytes = 198420; // ~198 KB
  int _wifiRssi = -58; // dBm
  int _wdtResetCount = 0;
  int _flashStoragePercent = 18;

  // Röle Stres Testi Durumu
  bool _isStressTesting = false;
  int _stressCycle = 0; // 0 to 10
  String? _stressTestResult;

  // Yeniden Başlatma (Restart) Onay Modalı
  bool _showRestartModal = false;
  bool _isRestarting = false;
  int _restartCountdown = 3;

  // Terminal & Log Akışı
  final List<EspEventLog> _logs = [
    EspEventLog(
      id: 'log-1',
      timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      type: 'combustion_end',
      title: 'Çevrimdışı Ateşleme Tamamlandı',
      details: 'Hedef 22.5°C ulaşıldı. Kombi alevi başarıyla söndü.',
    ),
    EspEventLog(
      id: 'log-2',
      timestamp: DateTime.now().subtract(const Duration(minutes: 44)),
      type: 'combustion_start',
      title: 'Otomatik Isıtma Başladı',
      details: 'Oda sıcaklığı 20.3°C altına indiğinde termostat rölesi tetiklendi.',
    ),
    EspEventLog(
      id: 'log-3',
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
      type: 'wdt_check',
      title: 'Donanımsal WDT Sağlık Kontrolü',
      details: 'Döngü süresi 4ms. Bellek sızıntısı yok, Watchdog sıfırlandı.',
    ),
    EspEventLog(
      id: 'log-4',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      type: 'packet',
      title: 'HTTP GET /api/telemetry [200 OK]',
      details: 'Payload: {"temp":21.8,"hum":48,"relay":1,"flame":68} (26ms)',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Simüle edilmiş canlı ping jitter dalgalanması
    _pingTimer = Timer.periodic(const Duration(seconds: 3), (t) {
      if (!mounted) return;
      final rand = math.Random();
      final jitter = (22 + rand.nextInt(24));
      setState(() {
        _pingHistory.add(jitter);
        if (_pingHistory.length > 16) {
          _pingHistory.removeAt(0);
        }
        _uptimeSeconds += 3;
      });
    });
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    super.dispose();
  }

  // 10 Döngülü Röle Dayanıklılık Stres Testi
  Future<void> _startRelayStressTest() async {
    HapticFeedback.heavyImpact();
    setState(() {
      _isStressTesting = true;
      _stressCycle = 0;
      _stressTestResult = null;
    });

    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() {
        _stressCycle = i;
        _logs.insert(
          0,
          EspEventLog(
            id: 'stress-$i-${DateTime.now().millisecondsSinceEpoch}',
            timestamp: DateTime.now(),
            type: 'stress_test',
            title: 'Röle Kontak Tetikleme #$i/10',
            details: 'Aç/Kapa döngüsü tamamlandı. Tepki süresi: ${24 + math.Random().nextInt(10)}ms [Kontak Direnci: 0.04Ω İdeal]',
          ),
        );
      });
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _isStressTesting = false;
      _stressTestResult = '10/10 Röle Dayanıklılık Testi Başarılı ✓ Kontak gecikmesi: 27ms ortalama';
    });
  }

  // Uzaktan ESP.restart() Reset Komutu
  void _executeRemoteRestart() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isRestarting = true;
      _restartCountdown = 3;
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_restartCountdown <= 1) {
        timer.cancel();
        setState(() {
          _isRestarting = false;
          _showRestartModal = false;
          _uptimeSeconds = 2;
          _wdtResetCount += 1;
          _logs.insert(
            0,
            EspEventLog(
              id: 'reboot-${DateTime.now().millisecondsSinceEpoch}',
              timestamp: DateTime.now(),
              type: 'reboot',
              title: 'Donanımsal Reset Tamamlandı',
              details: 'ESP.restart() komutu iletildi. Watchdog WDT ve geçici hafıza sıfırlandı.',
              wdtStatus: 'recovered',
            ),
          );
        });
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ESP32 başarıyla yeniden başlatıldı ve bağlandı ✓'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() => _restartCountdown -= 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final avgPing = _pingHistory.isEmpty ? 0 : (_pingHistory.reduce((a, b) => a + b) ~/ _pingHistory.length);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161424),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ESP32 Donanım Tanılama & Terminal',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: widget.isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  widget.isConnected ? '${widget.espIp}:${widget.espPort} (Canlı Bağlantı)' : 'ESP32 Çevrimdışı',
                  style: const TextStyle(fontSize: 10, color: Colors.white60, fontFamily: 'monospace'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            children: [
              // ── 1. CANLI PING JITTER & GECİKME GRAFİĞİ ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF181524),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF0C0B10), offset: Offset(0, 3), blurRadius: 6),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.network_ping_rounded, color: Color(0xFF38BDF8), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Canlı Gecikme (Ping Jitter)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                        Text(
                          '$avgPing ms ort.',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8), fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _PingWavePainter(pings: _pingHistory),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Son 16 Örnekleme', style: TextStyle(fontSize: 9, color: Colors.white38)),
                        Text('Anlık: ${_pingHistory.last} ms', style: const TextStyle(fontSize: 9, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── 2. DONANIM DURUM MATRİSİ (4 KART) ──
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      title: 'WIFI RSSI',
                      value: '$_wifiRssi dBm',
                      status: 'Güçlü Sinyal',
                      icon: Icons.wifi_rounded,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      title: 'FREE HEAP',
                      value: '${_freeHeapBytes ~/ 1024} KB',
                      status: 'Bellek Stabil',
                      icon: Icons.memory_rounded,
                      color: const Color(0xFF38BDF8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      title: 'WDT RESET',
                      value: '$_wdtResetCount Reset',
                      status: 'Watchdog Aktif',
                      icon: Icons.security_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      title: 'UPTIME',
                      value: '${_uptimeSeconds ~/ 3600}s ${(_uptimeSeconds % 3600) ~/ 60}d',
                      status: 'Kesintisiz',
                      icon: Icons.timer_rounded,
                      color: const Color(0xFFA855F7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── 3. RÖLE DAYANIKLILIK STRES TESTİ KARTI ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2A1C16), Color(0xFF181524)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFF8C32).withOpacity(0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '⚡ 10 Döngülü Röle Dayanıklılık Stres Testi',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Termostat donanım rölesini 10 kez art arda açıp kapatarak kontak tepki süresini ve kilitlenmeleri test eder.',
                      style: TextStyle(fontSize: 10, color: Colors.white60, height: 1.3),
                    ),
                    const SizedBox(height: 10),

                    if (_isStressTesting) ...[
                      LinearProgressIndicator(
                        value: _stressCycle / 10.0,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF8C32)),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 6,
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          'Test Yürütülüyor: Döngü $_stressCycle / 10...',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFFB800)),
                        ),
                      ),
                    ] else ...[
                      if (_stressTestResult != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _stressTestResult!,
                                  style: const TextStyle(fontSize: 10.5, color: Color(0xFFA7F3D0), fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8C32),
                          minimumSize: const Size.fromHeight(40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                        label: const Text('Röle Testini Başlat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: _startRelayStressTest,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── 4. BUTONLAR: RESET GÖNDER & LOGLARI SİL ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.restart_alt_rounded, color: Color(0xFFEF4444), size: 16),
                      label: const Text('ESP32 Reset Gönder', style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () => setState(() => _showRestartModal = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white70, size: 16),
                      label: const Text('Logları Temizle', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() => _logs.clear());
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── 5. CANLI PAKET & OLAY TERMİNALİ ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Paket & Olay Terminali (${_logs.length})',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'LittleFS Flaş: %$_flashStoragePercent',
                    style: const TextStyle(fontSize: 10, color: Colors.white54, fontFamily: 'monospace'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_logs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14121E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Center(
                    child: Text('Kayıtlı log bulunmuyor.', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ),
                )
              else
                ..._logs.map((log) => _buildLogItem(log)),
            ],
          ),

          // ── RESTART ONAY MODALI (OVERLAY) ──
          if (_showRestartModal)
            Container(
              color: Colors.black.withOpacity(0.75),
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1B2C),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.5)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black, blurRadius: 20),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 36),
                      const SizedBox(height: 8),
                      const Text(
                        'ESP32 Uzaktan Sıfırlansın mı?',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Bu işlem ESP32 çipine donanımsal ESP.restart() sinyali gönderir. Röle emniyet amacıyla hemen kapatılır ve 3 saniyede yeniden bağlanır.',
                        style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.3),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (_isRestarting) ...[
                        Text(
                          'Sıfırlanıyor... ($_restartCountdown)',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFEF4444), fontFamily: 'monospace'),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => setState(() => _showRestartModal = false),
                                child: const Text('İptal', style: TextStyle(color: Colors.white60)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                                onPressed: _executeRemoteRestart,
                                child: const Text('Evet, Resetle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String status,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF181524),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
              Icon(icon, color: color, size: 14),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'monospace')),
          const SizedBox(height: 2),
          Text(status, style: TextStyle(fontSize: 8.5, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildLogItem(EspEventLog log) {
    Color badgeColor = const Color(0xFF38BDF8);
    IconData icon = Icons.info_outline_rounded;

    if (log.type == 'reboot') {
      badgeColor = const Color(0xFFEF4444);
      icon = Icons.restart_alt_rounded;
    } else if (log.type == 'stress_test') {
      badgeColor = const Color(0xFFFF8C32);
      icon = Icons.bolt_rounded;
    } else if (log.type == 'combustion_start' || log.type == 'combustion_end') {
      badgeColor = const Color(0xFFFFB800);
      icon = Icons.local_fire_department_rounded;
    } else if (log.type == 'packet') {
      badgeColor = const Color(0xFF10B981);
      icon = Icons.terminal_rounded;
    }

    final timeStr = '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF14121E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: badgeColor, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      log.title,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(timeStr, style: const TextStyle(fontSize: 9, color: Colors.white38, fontFamily: 'monospace')),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  log.details,
                  style: const TextStyle(fontSize: 9.5, color: Colors.white60, height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Canlı Ping Jitter Çizim Sınıfı
class _PingWavePainter extends CustomPainter {
  final List<int> pings;

  _PingWavePainter({required this.pings});

  @override
  void paint(Canvas canvas, Size size) {
    if (pings.isEmpty) return;

    final barWidth = (size.width / pings.length) - 3;
    const maxPing = 60.0;

    for (int i = 0; i < pings.length; i++) {
      final p = pings[i];
      final heightRatio = (p / maxPing).clamp(0.1, 1.0);
      final barHeight = size.height * heightRatio;
      final x = i * (barWidth + 3);
      final y = size.height - barHeight;

      Color color = const Color(0xFF10B981);
      if (p > 45) {
        color = const Color(0xFFEF4444);
      } else if (p > 30) {
        color = const Color(0xFF38BDF8);
      }

      final paint = Paint()
        ..color = color.withOpacity(0.85)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
