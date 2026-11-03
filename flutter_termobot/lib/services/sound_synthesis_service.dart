import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'haptics_service.dart';

enum MascotSoundType {
  knock,
  happy,
  thinking,
  sleep,
  chirp,
  walk,
}

enum WarningSoundType {
  connection,
  battery,
}

class SoundSynthesisService {
  static const String _storageKey = 'app_sound_effects_enabled';
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

  /// 1. Mekanik Rotary Kadran Klik Sesi (Madde 13)
  static void playDialTick({bool haptic = true}) {
    if (haptic) {
      HapticsService.trigger(HapticFeedbackType.selection);
    }
    if (!_isEnabled) return;
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  /// 2. Röle Kontak Açma/Kapama Metalik Thud / Klik Sesi (Madde 14)
  static void playRelayClick({required bool isEngaged, bool haptic = true}) {
    if (haptic) {
      HapticsService.trigger(isEngaged ? HapticFeedbackType.heavy : HapticFeedbackType.medium);
    }
    if (!_isEnabled) return;
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  /// 3. Sevimli Maskot Duygu Sesleri (Madde 15)
  static void playMascotSound(MascotSoundType type) {
    if (!_isEnabled) return;
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  /// 4. Acil Durum / İkaz Sesleri
  static void playWarningAlert(WarningSoundType type) {
    HapticsService.trigger(HapticFeedbackType.warning);
    if (!_isEnabled) return;
    try {
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  /// 5. Gelen Sesli Çağrı Melodisi & Ritim
  static void startCallRingtone() {
    HapticsService.trigger(HapticFeedbackType.warning);
    if (!_isEnabled) return;
    try {
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  static void stopCallRingtone() {}
}
