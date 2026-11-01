import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MascotWidget extends StatefulWidget {
  final bool isHeating;
  final double currentTemp;
  final double targetTemp;

  const MascotWidget({
    super.key,
    required this.isHeating,
    required this.currentTemp,
    required this.targetTemp,
  });

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget> with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  String _speechMessage = 'Merhaba! Odanızı izliyorum.';
  bool _showBubble = false;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _onMascotTap() {
    HapticFeedback.lightImpact();
    setState(() {
      _showBubble = true;
      if (widget.isHeating) {
        _speechMessage =
            '🔥 Kombi aktif! Hedef ${widget.targetTemp}°C için alev modülasyonu devrede.';
      } else {
        _speechMessage =
            '🛋️ Oda şu an ${widget.currentTemp}°C. Sıcaklık ideal konfor aralığında.';
      }
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _showBubble = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onMascotTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Konuşma Baloncuğu
          AnimatedOpacity(
            opacity: _showBubble ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF6A00).withOpacity(0.4)),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Text(
                _speechMessage,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),

          // Zıplayan Maskot Gövdesi
          AnimatedBuilder(
            animation: _bounceController,
            builder: (context, child) {
              final offset = _bounceController.value * 6.0;
              return Transform.translate(
                offset: Offset(0, -offset),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: widget.isHeating
                          ? [const Color(0xFFFF6A00), const Color(0xFFFF3344)]
                          : [const Color(0xFF38BDF8), const Color(0xFF6366F1)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.isHeating
                                ? const Color(0xFFFF6A00)
                                : const Color(0xFF38BDF8))
                            .withOpacity(0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.isHeating ? '🔥' : '🤖',
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
