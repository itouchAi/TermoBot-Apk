import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/thermostat_state.dart';

class EspService {
  static final EspService _instance = EspService._internal();
  factory EspService() => _instance;
  EspService._internal();

  /// Hysteresis value in Celsius (kombinin sık devreye girip çıkmasını önler)
  final double hysteresis = 0.4;

  /// Termostat algoritması: Röle ve modülasyon hesabı
  ThermostatState computeThermostatLogic(ThermostatState current) {
    bool nextRelay = current.isRelayActive;
    int nextModulation = 0;

    final diff = current.targetTemp - current.currentTemp;

    if (current.currentTemp <= (current.targetTemp - hysteresis)) {
      nextRelay = true;
    } else if (current.currentTemp >= current.targetTemp) {
      nextRelay = false;
    }

    if (nextRelay) {
      if (diff >= 2.0) {
        nextModulation = 100;
      } else if (diff >= 1.0) {
        nextModulation = 75;
      } else if (diff >= 0.5) {
        nextModulation = 50;
      } else {
        nextModulation = 30;
      }
    } else {
      nextModulation = 0;
    }

    return current.copyWith(
      isRelayActive: nextRelay,
      flameModulation: nextModulation,
    );
  }

  /// Gerçek ESP32 cihazına hedef sıcaklık gönder
  Future<bool> sendTargetToEsp(String ip, double targetTemp) async {
    try {
      final uri = Uri.parse('http://$ip/api/set?target=$targetTemp');
      final res = await http.get(uri).timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Gerçek ESP32'den canlı sensör verisi çek
  Future<Map<String, dynamic>?> fetchEspTelemetry(String ip) async {
    try {
      final uri = Uri.parse('http://$ip/api/telemetry');
      final res = await http.get(uri).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // offline / timeout
    }
    return null;
  }
}
