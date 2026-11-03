import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/heatmap_matrix_widget.dart';

class HistoryStorageService {
  static const String _storageKey = 'smart_thermostat_historical_db_v2';
  static const String _unitPriceKey = 'smart_thermostat_gas_unit_price';

  static final HistoryStorageService _instance = HistoryStorageService._internal();
  factory HistoryStorageService() => _instance;
  HistoryStorageService._internal();

  /// Doğalgaz birim fiyatını (₺/m³) yükle
  Future<double> getGasUnitPrice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_unitPriceKey) ?? 10.25;
    } catch (_) {
      return 10.25;
    }
  }

  /// Doğalgaz birim fiyatını kaydet
  Future<void> setGasUnitPrice(double price) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_unitPriceKey, price);
    } catch (_) {}
  }

  /// Kalıcı geçmiş verilerini yükler. Eğer boşsa 7 günlük gerçekçi başlangıç verisini kaydeder ve döner.
  Future<List<HeatmapDayRecord>> loadHistoricalWeek() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        return decoded.map((item) {
          final map = item as Map<String, dynamic>;
          final hoursList = (map['hours'] as List<dynamic>).map((h) {
            final hMap = h as Map<String, dynamic>;
            return HeatmapHourData(
              hour: (hMap['hour'] as num).toInt(),
              temp: (hMap['temp'] as num).toDouble(),
              target: (hMap['target'] as num).toDouble(),
              isHeating: hMap['isHeating'] as bool? ?? false,
              flamePercent: (hMap['flamePercent'] as num?)?.toInt() ?? 0,
              gasM3: (hMap['gasM3'] as num?)?.toDouble() ?? 0.0,
            );
          }).toList();

          return HeatmapDayRecord(
            dateKey: map['dateKey'] as String,
            dateTitle: map['dateTitle'] as String,
            dayName: map['dayName'] as String,
            avgTemp: (map['avgTemp'] as num).toDouble(),
            totalActiveMinutes: (map['totalActiveMinutes'] as num).toInt(),
            totalGasM3: (map['totalGasM3'] as num).toDouble(),
            hours: hoursList,
          );
        }).toList();
      }
    } catch (e) {
      // Hata durumunda varsayılan veri setine geçilir
    }

    // Başlangıç 7 günlük (168 hücre) seti oluştur ve kalıcı hafızaya yaz
    final defaultWeek = _generateDefaultWeek();
    await saveHistoricalWeek(defaultWeek);
    return defaultWeek;
  }

  /// 7 günlük geçmişi SharedPreferences içine JSON olarak yazar
  Future<void> saveHistoricalWeek(List<HeatmapDayRecord> week) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listData = week.map((d) {
        return {
          'dateKey': d.dateKey,
          'dateTitle': d.dateTitle,
          'dayName': d.dayName,
          'avgTemp': d.avgTemp,
          'totalActiveMinutes': d.totalActiveMinutes,
          'totalGasM3': d.totalGasM3,
          'hours': d.hours.map((h) => {
            'hour': h.hour,
            'temp': h.temp,
            'target': h.target,
            'isHeating': h.isHeating,
            'flamePercent': h.flamePercent,
            'gasM3': h.gasM3,
          }).toList(),
        };
      }).toList();

      await prefs.setString(_storageKey, jsonEncode(listData));
    } catch (_) {}
  }

  /// Tüm geçmişi sıfırlar
  Future<void> resetHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }

  /// 7 günlük gerçekçi telemetri seti üretici
  List<HeatmapDayRecord> _generateDefaultWeek() {
    final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final titles = [
      'Pazartesi (12 Eki)',
      'Salı (13 Eki)',
      'Çarşamba (14 Eki)',
      'Perşembe (15 Eki)',
      'Cuma (16 Eki)',
      'Cumartesi (17 Eki)',
      'Pazar (Bugün)',
    ];

    return List.generate(7, (dayIdx) {
      final hours = List.generate(24, (h) {
        double baseTemp = 19.0;
        bool heating = false;
        int flame = 0;
        double gas = 0.0;

        if (h >= 0 && h < 6) {
          baseTemp = 18.2 + (dayIdx * 0.08) + (h * 0.1);
          if (h == 3 || h == 4) {
            heating = true;
            flame = 35;
            gas = 0.18;
          }
        } else if (h >= 6 && h < 9) {
          baseTemp = 20.4 + (h - 6) * 0.7;
          heating = true;
          flame = 80;
          gas = 0.45;
        } else if (h >= 9 && h < 17) {
          baseTemp = 21.8 + ((h % 3) * 0.2);
          heating = (h == 12 || h == 15);
          flame = heating ? 40 : 0;
          gas = heating ? 0.22 : 0.0;
        } else if (h >= 17 && h < 22) {
          baseTemp = 22.4 + ((h % 2) * 0.3);
          heating = true;
          flame = 65;
          gas = 0.38;
        } else {
          baseTemp = 21.0 - ((h - 22) * 0.5);
          heating = false;
        }

        return HeatmapHourData(
          hour: h,
          temp: (baseTemp * 10).round() / 10.0,
          target: heating ? 22.5 : 19.5,
          isHeating: heating,
          flamePercent: flame,
          gasM3: gas,
        );
      });

      final activeMin = hours.where((h) => h.isHeating).length * 42;
      final totalGas = hours.fold(0.0, (acc, h) => acc + h.gasM3);
      final avgTemp = hours.fold(0.0, (acc, h) => acc + h.temp) / 24.0;

      return HeatmapDayRecord(
        dateKey: '2026-10-${12 + dayIdx}',
        dateTitle: titles[dayIdx],
        dayName: days[dayIdx],
        avgTemp: (avgTemp * 10).round() / 10.0,
        totalActiveMinutes: activeMin,
        totalGasM3: (totalGas * 100).round() / 100.0,
        hours: hours,
      );
    });
  }
}
