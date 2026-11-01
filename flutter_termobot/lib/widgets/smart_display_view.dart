import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class SmartDisplayView extends StatefulWidget {
  final double currentTemp;
  final double targetTemp;
  final bool isHeating;
  final VoidCallback onDismiss;

  const SmartDisplayView({
    super.key,
    required this.currentTemp,
    required this.targetTemp,
    required this.isHeating,
    required this.onDismiss,
  });

  @override
  State<SmartDisplayView> createState() => _SmartDisplayViewState();
}

class _SmartDisplayViewState extends State<SmartDisplayView> {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(_now);
    final dateStr = DateFormat('EEEE, d MMMM', 'tr_TR').format(_now);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onDismiss();
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient Arka Plan Işıması
            Center(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (widget.isHeating ? const Color(0xFFFF6A00) : const Color(0xFF6366F1))
                      .withOpacity(0.12),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isHeating
                              ? const Color(0xFFFF6A00)
                              : const Color(0xFF6366F1))
                          .withOpacity(0.2),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Üst Bar: Kapatma İpucu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.tv, color: Colors.white70, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Smart Display Ambiyans',
                                style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white60),
                          onPressed: widget.onDismiss,
                        ),
                      ],
                    ),

                    // Merkez: Dev Dijital Saat & Tarih
                    Column(
                      children: [
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 92,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -4,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // Alt: Termostat Telemetri Göstergesi
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131926),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('ODA SICAKLIĞI',
                                  style: TextStyle(fontSize: 11, color: Colors.white38)),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.currentTemp.toStringAsFixed(1)}°C',
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 40, color: Colors.white12),
                          Column(
                            children: [
                              const Text('HEDEF DERECE',
                                  style: TextStyle(fontSize: 11, color: Colors.white38)),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.targetTemp.toStringAsFixed(1)}°C',
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFFFAA00)),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 40, color: Colors.white12),
                          Column(
                            children: [
                              const Text('DURUM',
                                  style: TextStyle(fontSize: 11, color: Colors.white38)),
                              const SizedBox(height: 4),
                              Text(
                                widget.isHeating ? '🔥 YANIYOR' : '❄️ BEKLEME',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: widget.isHeating
                                      ? const Color(0xFFFF6A00)
                                      : Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
