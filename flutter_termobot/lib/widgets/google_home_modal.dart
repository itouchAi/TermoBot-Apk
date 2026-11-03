import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GoogleHomeModal extends StatefulWidget {
  final bool isEnabled;
  final ValueChanged<bool> onToggleEnabled;

  const GoogleHomeModal({
    super.key,
    required this.isEnabled,
    required this.onToggleEnabled,
  });

  @override
  State<GoogleHomeModal> createState() => _GoogleHomeModalState();
}

class _GoogleHomeModalState extends State<GoogleHomeModal> {
  String _pairingPin = '748-291';
  bool _isMatterActive = true;

  void _regeneratePin() {
    HapticFeedback.selectionClick();
    final r1 = math.Random().nextInt(900) + 100;
    final r2 = math.Random().nextInt(900) + 100;
    setState(() => _pairingPin = '$r1-$r2');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF14121E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.home_rounded, color: Color(0xFF4285F4), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Google Home & Matter Köprüsü',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white60),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 16),

          // Entegrasyon Aç/Kapa Switch
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B29),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.cast_connected_rounded, color: Color(0xFF4285F4), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Google Home Köprüsü', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('Google Asistan ile sesli kontrol', style: TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ),
                Switch(
                  value: widget.isEnabled,
                  activeColor: const Color(0xFF4285F4),
                  onChanged: (v) {
                    HapticFeedback.mediumImpact();
                    widget.onToggleEnabled(v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Matter Eşleştirme Kodu Kartı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1F36), Color(0xFF121424)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF4285F4).withOpacity(0.35)),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('MATTER EŞLEŞTİRME KODU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                    Icon(Icons.qr_code_2_rounded, color: Color(0xFF4285F4), size: 18),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _pairingPin,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF60A5FA)),
                  label: const Text('Yeni Kod Üret', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 11)),
                  onPressed: _regeneratePin,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Sesli Komut Örnekleri
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B29),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ÖRNEK ASİSTAN KOMUTLARI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                SizedBox(height: 6),
                Text('• "Hey Google, salon termostatını 22.5 derece yap"', style: TextStyle(color: Colors.white70, fontSize: 11)),
                SizedBox(height: 4),
                Text('• "Hey Google, kombiyi kapat"', style: TextStyle(color: Colors.white70, fontSize: 11)),
                SizedBox(height: 4),
                Text('• "Hey Google, oda sıcaklığı kaç derece?"', style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}
