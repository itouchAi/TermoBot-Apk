import 'dart:async';
import 'package:flutter/material.dart';

class SmartDisplayControlsPill extends StatefulWidget {
  final int brightnessPercent;
  final ValueChanged<int> onBrightnessChange;
  final VoidCallback onClose;

  const SmartDisplayControlsPill({
    super.key,
    required this.brightnessPercent,
    required this.onBrightnessChange,
    required this.onClose,
  });

  @override
  State<SmartDisplayControlsPill> createState() => _SmartDisplayControlsPillState();
}

class _SmartDisplayControlsPillState extends State<SmartDisplayControlsPill> {
  bool _isExpanded = false;
  Timer? _autoCollapseTimer;

  void _scheduleAutoCollapse() {
    _autoCollapseTimer?.cancel();
    _autoCollapseTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _isExpanded = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _autoCollapseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _scheduleAutoCollapse,
      behavior: HitTestBehavior.opaque,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: !_isExpanded
            ? _buildMinimizedPill()
            : _buildExpandedBar(),
      ),
    );
  }

  Widget _buildMinimizedPill() {
    return InkWell(
      key: const ValueKey('minimized_controls'),
      onTap: () {
        setState(() => _isExpanded = true);
        _scheduleAutoCollapse();
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sun Icon (amber)
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.35)),
              ),
              child: const Icon(
                Icons.light_mode_rounded,
                size: 15,
                color: Color(0xFFFCD34D),
              ),
            ),
            const SizedBox(width: 6),

            // Red Circular Exit Button
            InkWell(
              onTap: widget.onClose,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE11D48),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE11D48).withValues(alpha: 0.35),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
              ),
            ),
            const SizedBox(width: 4),

            // Expand Chevron
            const Icon(
              Icons.keyboard_arrow_up_rounded,
              size: 18,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedBar() {
    return Container(
      key: const ValueKey('expanded_controls'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
            blurRadius: 18,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Brightness Slider Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.light_mode_rounded,
                  size: 14,
                  color: Color(0xFFFCD34D),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 90,
                  height: 24,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      activeTrackColor: const Color(0xFFFBBF24),
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      min: 10,
                      max: 100,
                      divisions: 18,
                      value: widget.brightnessPercent.toDouble(),
                      onChanged: (val) {
                        _scheduleAutoCollapse();
                        widget.onBrightnessChange(val.round());
                      },
                    ),
                  ),
                ),
                Text(
                  '%${widget.brightnessPercent}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFCD34D),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Red Exit Button
          InkWell(
            onTap: widget.onClose,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE11D48),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE11D48).withValues(alpha: 0.35),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
            ),
          ),
          const SizedBox(width: 4),

          // Collapse Chevron
          InkWell(
            onTap: () {
              setState(() => _isExpanded = false);
            },
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
