import 'dart:async';
import 'package:flutter/material.dart';

class LuxuryMediaBar extends StatefulWidget {
  final String mediaType; // 'audio' | 'video' | 'image'
  final bool isPlaying;
  final VoidCallback onTogglePlay;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool isMuted;
  final VoidCallback onToggleMute;
  final double volume; // 0.0 - 1.0
  final ValueChanged<double> onVolumeChange;
  final bool isLoop;
  final VoidCallback onToggleLoop;

  const LuxuryMediaBar({
    super.key,
    this.mediaType = 'video',
    required this.isPlaying,
    required this.onTogglePlay,
    required this.onPrevious,
    required this.onNext,
    this.isMuted = false,
    required this.onToggleMute,
    this.volume = 0.8,
    required this.onVolumeChange,
    this.isLoop = true,
    required this.onToggleLoop,
  });

  @override
  State<LuxuryMediaBar> createState() => _LuxuryMediaBarState();
}

class _LuxuryMediaBarState extends State<LuxuryMediaBar> {
  bool _isExpanded = false;
  bool _isVolumeSliderOpen = false;
  Timer? _autoCollapseTimer;

  void _scheduleAutoCollapse() {
    _autoCollapseTimer?.cancel();
    _autoCollapseTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _isExpanded = false;
          _isVolumeSliderOpen = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _autoCollapseTimer?.cancel();
    super.dispose();
  }

  IconData get _mediaIcon {
    switch (widget.mediaType) {
      case 'video':
        return Icons.tv_rounded;
      case 'audio':
        return Icons.music_note_rounded;
      default:
        return Icons.image_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _scheduleAutoCollapse,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Upward Vertical Volume Popover Slider
          if (_isVolumeSliderOpen)
            Positioned(
              bottom: 48,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '%${((widget.isMuted ? 0.0 : widget.volume) * 100).round()}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFCD34D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Rotated Vertical Slider
                    SizedBox(
                      height: 110,
                      width: 24,
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                            activeTrackColor: const Color(0xFFFBBF24),
                            inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                            thumbColor: Colors.white,
                            overlayColor: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                          ),
                          child: Slider(
                            min: 0.0,
                            max: 1.0,
                            value: widget.isMuted ? 0.0 : widget.volume,
                            onChanged: (val) {
                              _scheduleAutoCollapse();
                              widget.onVolumeChange(val);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        (widget.isMuted || widget.volume == 0)
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        size: 18,
                        color: (widget.isMuted || widget.volume == 0)
                            ? const Color(0xFFFB7185)
                            : const Color(0xFF34D399),
                      ),
                      onPressed: () {
                        _scheduleAutoCollapse();
                        widget.onToggleMute();
                      },
                    ),
                  ],
                ),
              ),
            ),

          // Main Bar (Collapsed vs Expanded)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: !_isExpanded
                ? _buildMinimizedPill()
                : _buildExpandedBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimizedPill() {
    return InkWell(
      key: const ValueKey('minimized'),
      onTap: () {
        setState(() {
          _isExpanded = true;
        });
        _scheduleAutoCollapse();
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            // TV Icon Badge with glowing pulse
            Stack(
              alignment: Alignment.center,
              children: [
                if (widget.isPlaying)
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                    ),
                  ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFF43F5E)],
                    ),
                  ),
                  child: Icon(_mediaIcon, size: 14, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(width: 8),

            // Play / Pause Circle
            InkWell(
              onTap: widget.onTogglePlay,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                child: Icon(
                  widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Volume Toggle
            InkWell(
              onTap: () {
                setState(() {
                  _isVolumeSliderOpen = !_isVolumeSliderOpen;
                });
                _scheduleAutoCollapse();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                child: Icon(
                  (widget.isMuted || widget.volume == 0)
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  size: 15,
                  color: (widget.isMuted || widget.volume == 0)
                      ? const Color(0xFFFB7185)
                      : const Color(0xFFFCD34D),
                ),
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
      key: const ValueKey('expanded'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
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
          // TV Icon Badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFF43F5E)],
              ),
            ),
            child: Icon(_mediaIcon, size: 15, color: Colors.white),
          ),
          const SizedBox(width: 8),

          Container(width: 1, height: 20, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(width: 8),

          // Previous Button
          InkWell(
            onTap: () {
              _scheduleAutoCollapse();
              widget.onPrevious();
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.skip_previous_rounded, size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 6),

          // Play/Pause Button
          InkWell(
            onTap: () {
              _scheduleAutoCollapse();
              widget.onTogglePlay();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFE11D48)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Next Button
          InkWell(
            onTap: () {
              _scheduleAutoCollapse();
              widget.onNext();
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.skip_next_rounded, size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),

          Container(width: 1, height: 20, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(width: 8),

          // Loop Toggle
          InkWell(
            onTap: () {
              _scheduleAutoCollapse();
              widget.onToggleLoop();
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: widget.isLoop
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: widget.isLoop
                    ? Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.4))
                    : null,
              ),
              child: Icon(
                Icons.repeat_rounded,
                size: 16,
                color: widget.isLoop ? const Color(0xFFFCD34D) : const Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Volume Button (Opens Upward Vertical Slider)
          InkWell(
            onTap: () {
              setState(() {
                _isVolumeSliderOpen = !_isVolumeSliderOpen;
              });
              _scheduleAutoCollapse();
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: _isVolumeSliderOpen
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: _isVolumeSliderOpen
                    ? Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.4))
                    : null,
              ),
              child: Icon(
                (widget.isMuted || widget.volume == 0)
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                size: 16,
                color: (widget.isMuted || widget.volume == 0)
                    ? const Color(0xFFFB7185)
                    : const Color(0xFF34D399),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Collapse Button
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = false;
                _isVolumeSliderOpen = false;
              });
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
