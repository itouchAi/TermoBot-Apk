import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/atmospheric_weather_canvas.dart';

class HourlyForecastItem {
  final String time;
  final String icon;
  final WeatherType condition;
  final String conditionText;
  final double temp;
  final int rainChancePct;
  final String kombiAdvice;

  const HourlyForecastItem({
    required this.time,
    required this.icon,
    required this.condition,
    required this.conditionText,
    required this.temp,
    required this.rainChancePct,
    required this.kombiAdvice,
  });
}

class DailyForecastItem {
  final String dayName;
  final String dateStr;
  final String condition;
  final WeatherType weatherType;
  final String icon;
  final double minTemp;
  final double maxTemp;
  final int rainProbability;
  final String advice;

  const DailyForecastItem({
    required this.dayName,
    required this.dateStr,
    required this.condition,
    required this.weatherType,
    required this.icon,
    required this.minTemp,
    required this.maxTemp,
    required this.rainProbability,
    required this.advice,
  });
}

class LocationItem {
  final String id;
  final String name;
  final String cityName;

  const LocationItem({
    required this.id,
    required this.name,
    required this.cityName,
  });

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'cityName': cityName};

  factory LocationItem.fromJson(Map<String, dynamic> json) => LocationItem(
        id: json['id'] as String,
        name: json['name'] as String,
        cityName: json['cityName'] as String,
      );
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  static const String _locationsStorageKey = 'termobot_custom_weather_locations';

  WeatherType _activeCondition = WeatherType.partlyCloudy;
  bool _isNight = false;

  late LocationItem _selectedLocation;
  List<LocationItem> _locations = [
    const LocationItem(id: 'loc-1', name: 'Ev', cityName: 'İstanbul'),
    const LocationItem(id: 'loc-2', name: 'Ofis', cityName: 'Ankara'),
    const LocationItem(id: 'loc-3', name: 'Yazlık', cityName: 'İzmir'),
    const LocationItem(id: 'loc-4', name: 'Dağ Evi', cityName: 'Bolu'),
  ];

  // 24 Saatlik Detaylı Tahmin Verisi
  final List<HourlyForecastItem> _hourlyList = const [
    HourlyForecastItem(time: '00:00', icon: '🌙', condition: WeatherType.partlyCloudy, conditionText: 'Açık Gece', temp: 12.1, rainChancePct: 5, kombiAdvice: 'Gece modu aktif. 19.5°C hedefi uygun.'),
    HourlyForecastItem(time: '02:00', icon: '🌙', condition: WeatherType.partlyCloudy, conditionText: 'Az Bulutlu', temp: 11.4, rainChancePct: 5, kombiAdvice: 'Sıcaklık 11°C altına iniyor.'),
    HourlyForecastItem(time: '04:00', icon: '🌫️', condition: WeatherType.fog, conditionText: 'Sisli & Serin', temp: 10.8, rainChancePct: 10, kombiAdvice: 'Radyatör sirkülasyonu devrede.'),
    HourlyForecastItem(time: '06:00', icon: '🌅', condition: WeatherType.sunny, conditionText: 'Gündoğumu', temp: 11.5, rainChancePct: 5, kombiAdvice: 'Sabah ısınma döngüsü başlıyor.'),
    HourlyForecastItem(time: '08:00', icon: '⛅', condition: WeatherType.partlyCloudy, conditionText: 'Parçalı Bulutlu', temp: 13.8, rainChancePct: 15, kombiAdvice: 'Konfor hedefi: 22.0°C.'),
    HourlyForecastItem(time: '10:00', icon: '🌤️', condition: WeatherType.partlyCloudy, conditionText: 'Güneşli Aralıklar', temp: 16.2, rainChancePct: 10, kombiAdvice: 'Güneş ışığı destekli tasarruf.'),
    HourlyForecastItem(time: '12:00', icon: '☀️', condition: WeatherType.sunny, conditionText: 'Güneşli', temp: 18.5, rainChancePct: 5, kombiAdvice: 'Oda sıcaklığı yeterli, kombi beklemede.'),
    HourlyForecastItem(time: '14:00', icon: '⛅', condition: WeatherType.partlyCloudy, conditionText: 'Hafif Rüzgar', temp: 19.0, rainChancePct: 10, kombiAdvice: 'Dış ortam 19°C, pencereleri açabilirsiniz.'),
    HourlyForecastItem(time: '16:00', icon: '🌦️', condition: WeatherType.rainy, conditionText: 'Yerel Yağış', temp: 16.7, rainChancePct: 45, kombiAdvice: 'Yağmur başladı, kombiyi 21.5°C yapın.'),
    HourlyForecastItem(time: '18:00', icon: '🌧️', condition: WeatherType.rainy, conditionText: 'Sağanak Yağış', temp: 14.5, rainChancePct: 70, kombiAdvice: 'Ani sıcaklık düşüşü: +1.0°C artış önerilir.'),
    HourlyForecastItem(time: '20:00', icon: '⛈️', condition: WeatherType.thunder, conditionText: 'Gök Gürültülü', temp: 13.2, rainChancePct: 80, kombiAdvice: 'Şimşek ve rüzgar; panjurları kapatın.'),
    HourlyForecastItem(time: '22:00', icon: '🌧️', condition: WeatherType.rainy, conditionText: 'Gece Yağmuru', temp: 12.6, rainChancePct: 60, kombiAdvice: 'Gece programına geçiş yapılıyor.'),
  ];

  // 5 Günlük Detaylı Tahmin Verisi
  final List<DailyForecastItem> _dailyList = const [
    DailyForecastItem(
      dayName: 'Bugün',
      dateStr: '2 Kas',
      condition: 'Parçalı Bulutlu',
      weatherType: WeatherType.partlyCloudy,
      icon: '⛅',
      minTemp: 10.8,
      maxTemp: 19.0,
      rainProbability: 25,
      advice: 'Gün ortası ılıman, akşam saatlerinde yerel yağmur geçişi bekleniyor.',
    ),
    DailyForecastItem(
      dayName: 'Salı',
      dateStr: '3 Kas',
      condition: 'Sağanak Yağmur',
      weatherType: WeatherType.rainy,
      icon: '🌧️',
      minTemp: 9.2,
      maxTemp: 14.6,
      rainProbability: 75,
      advice: 'Tüm gün kesintili yağmur ve poyraz. Kombi alev modülasyonu %65 tavsiye edilir.',
    ),
    DailyForecastItem(
      dayName: 'Çarşamba',
      dateStr: '4 Kas',
      condition: 'Fırtına & Şimşek',
      weatherType: WeatherType.thunder,
      icon: '⛈️',
      minTemp: 8.5,
      maxTemp: 13.0,
      rainProbability: 85,
      advice: 'Kuvvetli rüzgar ve şimşek. İzolasyon zayıf odalarda hedefi 22.5°C tutun.',
    ),
    DailyForecastItem(
      dayName: 'Perşembe',
      dateStr: '5 Kas',
      condition: 'Güneşli & Açık',
      weatherType: WeatherType.sunny,
      icon: '☀️',
      minTemp: 9.8,
      maxTemp: 18.2,
      rainProbability: 5,
      advice: 'Güneşli gökyüzü. Eko modda %24 doğalgaz tasarrufu sağlanabilir.',
    ),
    DailyForecastItem(
      dayName: 'Cuma',
      dateStr: '6 Kas',
      condition: 'Sisli & Soğuk',
      weatherType: WeatherType.fog,
      icon: '🌫️',
      minTemp: 6.5,
      maxTemp: 12.4,
      rainProbability: 15,
      advice: 'Yoğun sabah sisi ve düşük zemin sıcaklığı. Erken saatte konfor modunu başlatın.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedLocation = _locations.first;
    _loadSavedLocations();
  }

  Future<void> _loadSavedLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_locationsStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        final loaded = decoded.map((e) => LocationItem.fromJson(e as Map<String, dynamic>)).toList();
        if (loaded.isNotEmpty) {
          setState(() {
            _locations = loaded;
            _selectedLocation = loaded.first;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _saveLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_locations.map((l) => l.toJson()).toList());
      await prefs.setString(_locationsStorageKey, raw);
    } catch (_) {}
  }

  void _showAddLocationDialog() {
    final nameCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: 'İstanbul');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1A2C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Yeni Konum Ekle', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Konum Etiketi (Örn: Yazlık Ev, Ofis)',
                  labelStyle: const TextStyle(color: Colors.white60, fontSize: 11),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: cityCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Şehir İsmi (Örn: Antalya, Bolu)',
                  labelStyle: const TextStyle(color: Colors.white60, fontSize: 11),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C32)),
              onPressed: () {
                final n = nameCtrl.text.trim();
                final c = cityCtrl.text.trim();
                if (n.isNotEmpty && c.isNotEmpty) {
                  final newLoc = LocationItem(id: 'loc-${DateTime.now().millisecondsSinceEpoch}', name: n, cityName: c);
                  setState(() {
                    _locations.add(newLoc);
                    _selectedLocation = newLoc;
                  });
                  _saveLocations();
                  Navigator.pop(ctx);
                  HapticFeedback.lightImpact();
                }
              },
              child: const Text('Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showHourlyDetailsModal(HourlyForecastItem item) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1A2C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(item.icon, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Saat ${item.time} Detayı', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          Text(item.conditionText, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '${item.temp}°C',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.water_drop_rounded, color: Color(0xFF38BDF8), size: 18),
                    const SizedBox(width: 8),
                    Text('Yağış Olasılığı: %${item.rainChancePct}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C32).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFF8C32).withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tips_and_updates_rounded, color: Color(0xFFFFB800), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.kombiAdvice,
                        style: const TextStyle(color: Colors.white, fontSize: 11.5, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8C32),
                  minimumSize: const Size.fromHeight(42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Kapat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AtmosphericWeatherCanvas(
      weatherType: _activeCondition,
      isNight: _isNight,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        children: [
          // ── 1. ŞEHİR / KONUM SEÇİCİ VE YENİ EKLE BUTONU ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                ..._locations.map((loc) {
                  final isSel = _selectedLocation.id == loc.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _selectedLocation = loc);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFFF8C32) : const Color(0xFF1E1B29).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSel ? const Color(0xFFFFB800) : Colors.white12),
                          boxShadow: isSel
                              ? [BoxShadow(color: const Color(0xFFFF8C32).withOpacity(0.35), blurRadius: 6)]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 12, color: isSel ? Colors.white : Colors.white60),
                            const SizedBox(width: 4),
                            Text(
                              '${loc.name} (${loc.cityName})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSel ? Colors.white : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                // Yeni Konum Ekle Butonu
                GestureDetector(
                  onTap: _showAddLocationDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2638).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add_location_alt_rounded, size: 13, color: Color(0xFF38BDF8)),
                        SizedBox(width: 4),
                        Text('Konum Ekle', style: TextStyle(fontSize: 11, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── 2. CANLI HAVA DURUMU HERO KARTI ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF181524).withOpacity(0.85),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
              boxShadow: const [
                BoxShadow(color: Color(0xFF0C0B10), offset: Offset(0, 4), blurRadius: 10),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_selectedLocation.cityName}, Türkiye',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        Text(
                          '${_selectedLocation.name} • Parçalı Bulutlu • Nem %58',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    const Text('⛅', style: TextStyle(fontSize: 38)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '17.2°C',
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'monospace'),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Hissedilen: 16.5°C', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFFB800))),
                        Text('Rüzgar: 12 km/s KB', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── 3. GPU FİZİK EFEKTİ SEÇİCİ ŞERİT ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildWeatherChip('Güneşli', WeatherType.sunny, '☀️'),
                _buildWeatherChip('Parçalı', WeatherType.partlyCloudy, '⛅'),
                _buildWeatherChip('Bulutlu', WeatherType.cloudy, '☁️'),
                _buildWeatherChip('Yağmurlu', WeatherType.rainy, '🌧️'),
                _buildWeatherChip('Fırtına', WeatherType.thunder, '⛈️'),
                _buildWeatherChip('Karlı', WeatherType.snowy, '❄️'),
                _buildWeatherChip('Sisli', WeatherType.fog, '🌫️'),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isNight = !_isNight);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: _isNight ? const Color(0xFF38BDF8) : const Color(0xFF1E1B29),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(_isNight ? '🌙 Gece' : '☀️ Gündüz', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: _isNight ? Colors.black : Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── 4. 24 SAATLİK YATAY TAHMİN ŞERİDİ ──
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '24 Saatlik Sıcaklık & Yağış Şeridi',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                'Dokunup inceleyin',
                style: TextStyle(fontSize: 9.5, color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 8),

          SizedBox(
            height: 98,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _hourlyList.length,
              itemBuilder: (context, idx) {
                final h = _hourlyList[idx];
                return GestureDetector(
                  onTap: () => _showHourlyDetailsModal(h),
                  child: Container(
                    width: 68,
                    margin: const EdgeInsets.only(right: 7),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1B29).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(h.time, style: const TextStyle(fontSize: 10, color: Colors.white60, fontFamily: 'monospace')),
                        Text(h.icon, style: const TextStyle(fontSize: 18)),
                        Text('${h.temp.toInt()}°C', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace')),
                        if (h.rainChancePct > 20)
                          Text('%${h.rainChancePct}', style: const TextStyle(fontSize: 8.5, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold))
                        else
                          const Text('Açık', style: TextStyle(fontSize: 8, color: Colors.white38)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // ── 5. AKILLI KOMBİ HAVA TAVSİYESİ ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1926).withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFF8C32).withOpacity(0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.tips_and_updates_rounded, color: Color(0xFFFFB800), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Dış ortam sıcaklığı gece 10°C seviyesine inecek. Kombinizin konfor hedefini 22.0°C\'de tutmanız önerilir.',
                    style: TextStyle(fontSize: 10.5, color: Colors.white70, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── 6. 5 GÜNLÜK HAVA TAHMİNİ ──
          ..._dailyList.map((d) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1826).withOpacity(0.85),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 70,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.dayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(d.dateStr, style: const TextStyle(fontSize: 9, color: Colors.white38)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(d.icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(d.condition, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                  Row(
                    children: [
                      if (d.rainProbability > 20) ...[
                        Text('%${d.rainProbability}', style: const TextStyle(fontSize: 10, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                      ],
                      Text('${d.minTemp.toInt()}°', style: const TextStyle(fontSize: 12, color: Colors.white38, fontFamily: 'monospace')),
                      const Text(' / ', style: TextStyle(color: Colors.white24, fontSize: 10)),
                      Text('${d.maxTemp.toInt()}°', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace')),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWeatherChip(String label, WeatherType type, String icon) {
    final isSel = _activeCondition == type;
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _activeCondition = type);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFFFF8C32) : const Color(0xFF1E1B29).withOpacity(0.8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSel ? const Color(0xFFFFB800) : Colors.white12),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSel ? Colors.white : Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
