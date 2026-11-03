import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sound_synthesis_service.dart';

class VoiceCallOverlay extends StatefulWidget {
  final String callReason;
  final double currentTemp;
  final double targetTemp;
  final VoidCallback onDismiss;

  const VoiceCallOverlay({
    super.key,
    required this.callReason,
    required this.currentTemp,
    required this.targetTemp,
    required this.onDismiss,
  });

  @override
  State<VoiceCallOverlay> createState() => _VoiceCallOverlayState();
}

class _VoiceCallOverlayState extends State<VoiceCallOverlay> {
  bool _isAnswered = false;
  int _callDurationSec = 0;
  Timer? _callTimer;
  bool _isMuted = false;
  bool _isSpeakerOn = true;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    SoundSynthesisService.startCallRingtone();
  }

  @override
  void dispose() {
    SoundSynthesisService.stopCallRingtone();
    _callTimer?.cancel();
    super.dispose();
  }

  void _answerCall() {
    SoundSynthesisService.stopCallRingtone();
    HapticFeedback.mediumImpact();
    setState(() {
      _isAnswered = true;
    });
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDurationSec++;
        });
      }
    });
  }

  void _endCall() {
    SoundSynthesisService.stopCallRingtone();
    HapticFeedback.lightImpact();
    _callTimer?.cancel();
    widget.onDismiss();
  }

  String _formatDuration(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D14).withOpacity(0.97),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Üst Başlık & Arayan Bilgisi
              Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    _isAnswered ? 'Görüşme Devam Ediyor' : 'Gelen Sesli Asistan Araması',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'TermoBot AI Asistan',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isAnswered
                        ? _formatDuration(_callDurationSec)
                        : '+90 (850) 300 00 24 • Kombi Emniyet Hattı',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isAnswered ? const Color(0xFF00E5FF) : Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Çağrı Nedeni Rozeti
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6A00).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFF6A00).withOpacity(0.4)),
                    ),
                    child: Text(
                      widget.callReason == 'ignition'
                          ? '🔥 Kombi Ateşlendi: Hedef ${widget.targetTemp}°C (Oda: ${widget.currentTemp}°C)'
                          : '⚡ TermoBot Donanım & Sistem Testi',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFAA00),
                      ),
                    ),
                  ),
                ],
              ),

              // 2. Orta: Asistan Avatarı & Ses Dalgaları
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF6A00).withOpacity(0.1),
                      border: Border.all(
                        color: const Color(0xFFFF6A00).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF6A00), Color(0xFFFF3344)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x66FF6A00),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🤖', style: TextStyle(fontSize: 54)),
                    ),
                  ),
                ],
              ),

              // 3. Alt: Butonlar (Cevapla / Reddet veya Arama İçi Kontroller)
              if (!_isAnswered) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Kırmızı Reddet Butonu
                    GestureDetector(
                      onTap: _endCall,
                      child: Column(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFDC2626),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x66DC2626),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.call_end, color: Colors.white, size: 30),
                          ),
                          const SizedBox(height: 8),
                          const Text('Reddet',
                              style: TextStyle(fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ),

                    // Yeşil Cevapla Butonu
                    GestureDetector(
                      onTap: _answerCall,
                      child: Column(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF16A34A),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x6616A34A),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.call, color: Colors.white, size: 30),
                          ),
                          const SizedBox(height: 8),
                          const Text('Yanıtla',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Column(
                  children: [
                    // Arama İçi Tuşlar (Sessiz, Hoparlör, Kapat)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCallAction(
                          icon: _isMuted ? Icons.mic_off : Icons.mic,
                          label: _isMuted ? 'Sessizde' : 'Mikrofon',
                          isActive: _isMuted,
                          onTap: () => setState(() => _isMuted = !_isMuted),
                        ),
                        _buildCallAction(
                          icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                          label: 'Hoparlör',
                          isActive: _isSpeakerOn,
                          onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                        ),
                        _buildCallAction(
                          icon: Icons.dialpad,
                          label: 'Tuş Takımı',
                          isActive: false,
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    // Kırmızı Çağrıyı Sonlandır
                    GestureDetector(
                      onTap: _endCall,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFDC2626),
                          boxShadow: [
                            BoxShadow(color: Color(0x66DC2626), blurRadius: 20),
                          ],
                        ),
                        child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallAction({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.white.withOpacity(0.25) : Colors.white.withOpacity(0.08),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ],
      ),
    );
  }
}
