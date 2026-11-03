import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HapticFeedbackType {
  light,
  selection,
  medium,
  heavy,
  success,
  warning,
}

class HapticsService {
  static const String _storageKey = 'app_haptics_enabled';
  static bool _isEnabled = true;

  static bool get isEnabled => _isEnabled;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(_storageKey) ?? true;
    } catch (_) {
      _isEnabled = true;
    }
  }

  static Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_storageKey, enabled);
    } catch (_) {}
  }

  static void trigger(HapticFeedbackType type, {bool force = false}) {
    if (!force && !_isEnabled) return;

    try {
      switch (type) {
        case HapticFeedbackType.light:
          HapticFeedback.lightImpact();
          break;
        case HapticFeedbackType.selection:
          HapticFeedback.selectionClick();
          break;
        case HapticFeedbackType.medium:
          HapticFeedback.mediumImpact();
          break;
        case HapticFeedbackType.heavy:
          HapticFeedback.heavyImpact();
          break;
        case HapticFeedbackType.success:
          HapticFeedback.mediumImpact();
          Future.delayed(const Duration(milliseconds: 60), () {
            HapticFeedback.lightImpact();
          });
          break;
        case HapticFeedbackType.warning:
          HapticFeedback.vibrate();
          break;
      }
    } catch (_) {
      // Graceful fallback for devices without vibrator motors
    }
  }
}
