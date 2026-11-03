import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VoiceAssistantModal extends StatefulWidget {
  final double currentTemp;
  final double targetTemp;
  final bool isHeating;
  final ValueChanged<double> onSetTarget;
  final VoidCallback onToggleRelay;
  final ValueChanged<int> onNavigateToTab;

  const VoiceAssistantModal({
    super.key,
    required this.currentTemp,
    required this.targetTemp,
    required this.isHeating,
    required this.onSetTarget,
    required this.onToggleRelay,
    required this.onNavigateToTab,
  });

  @override
  State<VoiceAssistantModal> createState() => _VoiceAssistantModalState();
}

class _VoiceAssistantModalState extends State<VoiceAssistantModal> with SingleTickerProviderStateMixin {
  bool _isListening = false;
  String _transcript = '';
  String _responseFeedback = 'Dinliyorum... Bir komut söyleyin veya aşağıya yazın.';
  final TextEditingController _textCtrl = TextEditingController();
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _startSimulatedListening();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _startSimulatedListening() {
    setState(() {
      _isListening = true;
      _responseFeedback = 'Dinliyorum... "Kombiyi 23 derece yap", "Oda kaç derece?" veya "Raporu aç" diyebilirsiniz.';
    });
  }

  void _processCommand(String cmd) {
    HapticFeedback.mediumImpact();
    final lower = cmd.toLowerCase().trim();

    // Derece komutu arama
    final regExp = RegExp(r'(\d+([.,]\d+)?)');
    final match = regExp.firstMatch(lower);

    if (match != null && (lower.contains('derece') || lower.contains('yap') || lower.contains('ayarla'))) {
      final valStr = match.group(1)!.replaceAll(',', '.');
      final val = double.tryParse(valStr);
      if (val != null && val >= 16.0 && val <= 30.0) {
        widget.onSetTarget(val);
        setState(() {
          _isListening = false;
          _responseFeedback = '✓ Anlaşıldı! Termostat hedef sıcaklığı $val°C olarak ayarlandı.';
        });
        return;
      }
    }

    if (lower.contains('kapat') || lower.contains('söndür') || lower.contains('durdur')) {
      if (widget.isHeating) widget.onToggleRelay();
      setState(() {
        _isListening = false;
        _responseFeedback = '✓ Kombi ateşlemesi kapatıldı, emniyet beklemesine geçildi.';
      });
      return;
    }

    if (lower.contains('aç') || lower.contains('ateşle') || lower.contains('çalıştır')) {
      if (!widget.isHeating) widget.onToggleRelay();
      setState(() {
        _isListening = false;
        _responseFeedback = '✓ Kombi ateşlendi! Isıtma devresi çalışıyor.';
      });
      return;
    }

    if (lower.contains('sıcaklık') || lower.contains('kaç') || lower.contains('oda')) {
      setState(() {
        _isListening = false;
        _responseFeedback = 'ℹ️ Canlı oda sıcaklığı şu an ${widget.currentTemp}°C, hedefiniz ise ${widget.targetTemp}°C.';
      });
      return;
    }

    if (lower.contains('rapor') || lower.contains('grafik') || lower.contains('analiz')) {
      widget.onNavigateToTab(2);
      setState(() {
        _isListening = false;
        _responseFeedback = '✓ Sıcaklık ve tüketim analitiği ekranı açıldı.';
      });
      return;
    }

    if (lower.contains('program') || lower.contains('zaman') || lower.contains('haftalık')) {
      widget.onNavigateToTab(3);
      setState(() {
        _isListening = false;
        _responseFeedback = '✓ Haftalık zaman programlayıcı ekranı açıldı.';
      });
      return;
    }

    if (lower.contains('hava') || lower.contains('durum')) {
      widget.onNavigateToTab(1);
      setState(() {
        _isListening = false;
        _responseFeedback = '✓ Bölgesel hava durumu ve 5 günlük tahmin ekranı açıldı.';
      });
      return;
    }

    setState(() {
      _isListening = false;
      _responseFeedback = '🤔 "$cmd" komutu anlaşılamadı. Lütfen örneğin "Kombiyi 22 derece yap" diyebilirsiniz.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161422),
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

          // Başlık
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.mic_rounded, color: Color(0xFFFF8C32), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'TermoBot Akıllı Sesli Asistan',
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

          const SizedBox(height: 10),

          // Dalgalı Mikrofon Küresi
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (ctx, child) {
              final scale = _isListening ? 1.0 + (_pulseCtrl.value * 0.15) : 1.0;
              return Transform.scale(
                scale: scale,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _startSimulatedListening();
                  },
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFF9A4A), Color(0xFFFF5500)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF7A1A).withOpacity(_isListening ? 0.7 : 0.3),
                          blurRadius: _isListening ? 25 : 10,
                          spreadRadius: _isListening ? 4 : 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Yanıt ve Geri Bildirim Balonu
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF221F2E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              _responseFeedback,
              style: const TextStyle(fontSize: 12.5, color: Colors.white, height: 1.35),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 14),

          // Hızlı Örnek Komut Çipleri
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                'Kombiyi 22.5 yap',
                'Oda kaç derece?',
                'Kombiyi kapat',
                'Raporu göster',
                'Eko moduna geç',
              ].map((chip) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    backgroundColor: const Color(0xFF1E1B29),
                    side: const BorderSide(color: Colors.white12),
                    label: Text(chip, style: const TextStyle(fontSize: 11, color: Color(0xFFFFB800))),
                    onPressed: () => _processCommand(chip),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Manuel Metin Giriş Çubuğu
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Komutunuzu buraya yazın...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF1E1B29),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      _processCommand(val);
                      _textCtrl.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(backgroundColor: const Color(0xFFFF8C32)),
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                onPressed: () {
                  if (_textCtrl.text.trim().isNotEmpty) {
                    _processCommand(_textCtrl.text);
                    _textCtrl.clear();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
