import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Language { tr, en }

class I18n {
  static const String _storageKey = 'app_language_preference';
  static Language _currentLang = Language.tr;
  static final ValueNotifier<Language> languageNotifier =
      ValueNotifier<Language>(Language.tr);

  static Language get currentLang => _currentLang;
  static bool get isTurkish => _currentLang == Language.tr;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);
      if (saved == 'en') {
        _currentLang = Language.en;
      } else {
        _currentLang = Language.tr;
      }
      languageNotifier.value = _currentLang;
    } catch (_) {
      _currentLang = Language.tr;
    }
  }

  static Future<void> setLanguage(Language lang) async {
    _currentLang = lang;
    languageNotifier.value = lang;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, lang == Language.en ? 'en' : 'tr');
    } catch (_) {}
  }

  static Future<void> toggleLanguage() async {
    final next = _currentLang == Language.tr ? Language.en : Language.tr;
    await setLanguage(next);
  }

  static String t(String key) {
    final dict = _currentLang == Language.tr ? _trDictionary : _enDictionary;
    return dict[key] ?? _trDictionary[key] ?? key;
  }

  static final Map<String, String> _trDictionary = {
    // Header & Navigation
    'app_title': 'TermoBot',
    'location_istanbul': 'Ev (İstanbul)',
    'perf_ultra': '60 FPS',
    'tab_thermostat': 'Termostat',
    'tab_weather': 'Hava Durumu',
    'tab_report': 'Raporlar',
    'tab_program': 'Haftalık Program',

    // Termostat & Kadran
    'live_room': 'CANLI ODA',
    'target_temp': 'HEDEF TERMOSTAT',
    'active_heating': 'ATEŞLENDİ',
    'standby': 'BEKLEMEDE',
    'flame_modulation': 'Alev Gücü',
    'preset_eco': 'EKO (20.5°)',
    'preset_comfort': 'KONFOR (22.5°)',
    'preset_night': 'GECE (18.5°)',
    'preset_away': 'DIŞARIDA (16.0°)',
    'preset_boost': 'BOOST (24.0°)',
    'burner_on': 'Kombi Ateşlemede',
    'burner_off': 'Röle Beklemede',
    'today_active_time': 'Bugün Aktif Çalışma',
    'last_ignition': 'Son Ateşleme',
    'daily_burn_hours': 'saat',

    // Hava Durumu
    'weather_title': 'Atmosferik Hava & Tahmin',
    'weather_humidity': 'Nem Oranı',
    'weather_wind': 'Rüzgar Hızı',
    'weather_pressure': 'Hava Basıncı',
    'weather_rain_chance': 'Yağış İhtimali',
    'hourly_forecast': '24 Saatlik Tahmin Şeridi',
    'weekly_forecast': '5 Günlük Meteoroloji Görünümü',
    'kombi_advice': 'Kombi & Enerji Tavsiyesi',
    'add_location': 'Yeni Konum Ekle',

    // Raporlama & Geçmiş
    'reports_title': 'Tüketim & Donanım Raporu',
    'heatmap_168_title': '168 Saatlik Termal Isı Matrisi (7 Gün × 24 Saat)',
    'comfort_index_title': 'Termal Konfor & İklimlendirme İndeksi',
    'comfort_ideal': 'Mükemmel Konfor',
    'comfort_good': 'İyi Konfor',
    'comfort_moderate': 'Orta Konfor',
    'comfort_uncomfortable': 'Düşük Konfor',
    'cost_estimate': 'Tahmini Doğalgaz Faturası',
    'reset_history': 'Geçmiş Verilerini Sıfırla',

    // ESP32 & Donanım
    'esp_diagnostics_title': 'ESP32 Donanım Tanılama & Röle Stres Testi',
    'esp_rssi': 'Wi-Fi Sinyal Gücü (RSSI)',
    'esp_heap': 'Serbest RAM (Heap)',
    'esp_uptime': 'Çalışma Süresi (Uptime)',
    'esp_ping': 'Ping Gecikmesi (Jitter)',
    'esp_stress_test': '10 Döngülü Röle Dayanıklılık Testi',
    'esp_restart': 'Donanımı Uzaktan Yeniden Başlat (ESP.restart)',

    // Kripto Kasa & Telegram
    'vault_title': 'Kriptografik Donanım Kasası',
    'vault_locked': 'Kasa Kilitli',
    'vault_unlocked': 'Kasa Açık',
    'vault_pin': 'Güvenlik PIN Kodu',
    'vault_unlock_btn': 'Kasayı Aç',
    'vault_lock_btn': 'Kasayı Kilitle',
    'telegram_alerts': 'Telegram Acil Durum Bildirimleri',
    'telegram_token': 'Bot API Token',
    'telegram_chat_id': 'Telegram Chat ID',
    'telegram_test_btn': 'Test Bildirimi Gönder',

    // Smart Display
    'smart_display_title': 'Smart Display OLED Ambiyans',
    'brightness_label': 'Ekran Parlaklığı',
    'media_manager': 'Medya & Akış Yöneticisi',
    'equalizer_mode': 'Müzik Ekolayzır',

    // Genel
    'save': 'Kaydet',
    'cancel': 'İptal',
    'close': 'Kapat',
    'success': 'İşlem Başarılı',
    'warning': 'Uyarı',
    'error': 'Hata',
  };

  static final Map<String, String> _enDictionary = {
    // Header & Navigation
    'app_title': 'TermoBot',
    'location_istanbul': 'Home (Istanbul)',
    'perf_ultra': '60 FPS',
    'tab_thermostat': 'Thermostat',
    'tab_weather': 'Weather',
    'tab_report': 'Reports',
    'tab_program': 'Weekly Schedule',

    // Termostat & Kadran
    'live_room': 'LIVE ROOM',
    'target_temp': 'TARGET SETPOINT',
    'active_heating': 'HEATING ON',
    'standby': 'STANDBY',
    'flame_modulation': 'Flame Power',
    'preset_eco': 'ECO (20.5°)',
    'preset_comfort': 'COMFORT (22.5°)',
    'preset_night': 'NIGHT (18.5°)',
    'preset_away': 'AWAY (16.0°)',
    'preset_boost': 'BOOST (24.0°)',
    'burner_on': 'Boiler Ignited',
    'burner_off': 'Relay Standby',
    'today_active_time': 'Today Active Runtime',
    'last_ignition': 'Last Ignition',
    'daily_burn_hours': 'hours',

    // Hava Durumu
    'weather_title': 'Atmospheric Weather & Forecast',
    'weather_humidity': 'Humidity',
    'weather_wind': 'Wind Speed',
    'weather_pressure': 'Barometric Pressure',
    'weather_rain_chance': 'Precipitation Chance',
    'hourly_forecast': '24-Hour Forecast Ribbon',
    'weekly_forecast': '5-Day Meteorological Outlook',
    'kombi_advice': 'Boiler & Energy Advice',
    'add_location': 'Add Custom Location',

    // Raporlama & Geçmiş
    'reports_title': 'Consumption & Hardware Report',
    'heatmap_168_title': '168-Hour Thermal Heatmap (7 Days × 24 Hours)',
    'comfort_index_title': 'Thermal Comfort & Climate Index',
    'comfort_ideal': 'Ideal Comfort',
    'comfort_good': 'Good Comfort',
    'comfort_moderate': 'Moderate Comfort',
    'comfort_uncomfortable': 'Poor Comfort',
    'cost_estimate': 'Estimated Gas Utility Bill',
    'reset_history': 'Reset Historical Telemetry',

    // ESP32 & Donanım
    'esp_diagnostics_title': 'ESP32 Hardware Diagnostics & Relay Stress Test',
    'esp_rssi': 'Wi-Fi Signal Strength (RSSI)',
    'esp_heap': 'Free RAM (Heap)',
    'esp_uptime': 'System Uptime',
    'esp_ping': 'Ping Latency (Jitter)',
    'esp_stress_test': '10-Cycle Relay Endurance Stress Test',
    'esp_restart': 'Remote Hardware Restart (ESP.restart)',

    // Kripto Kasa & Telegram
    'vault_title': 'Cryptographic Hardware Vault',
    'vault_locked': 'Vault Locked',
    'vault_unlocked': 'Vault Unlocked',
    'vault_pin': 'Security PIN Code',
    'vault_unlock_btn': 'Unlock Vault',
    'vault_lock_btn': 'Lock Vault',
    'telegram_alerts': 'Telegram Emergency Alerts',
    'telegram_token': 'Bot API Token',
    'telegram_chat_id': 'Telegram Chat ID',
    'telegram_test_btn': 'Send Test Alert',

    // Smart Display
    'smart_display_title': 'Smart Display OLED Ambience',
    'brightness_label': 'Screen Brightness',
    'media_manager': 'Media & Stream Manager',
    'equalizer_mode': 'Music Equalizer',

    // Genel
    'save': 'Save',
    'cancel': 'Cancel',
    'close': 'Close',
    'success': 'Success',
    'warning': 'Warning',
    'error': 'Error',
  };
}
