import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class TelegramBotService {
  static Future<bool> sendRawMessage({
    required String botToken,
    required String chatId,
    required String text,
    String parseMode = 'HTML',
  }) async {
    final cleanToken = botToken.trim();
    final cleanChatId = chatId.trim();
    if (cleanToken.isEmpty || cleanChatId.isEmpty) return false;

    try {
      final uri = Uri.parse('https://api.telegram.org/bot$cleanToken/sendMessage');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': cleanChatId,
          'text': text,
          'parse_mode': parseMode,
          'disable_web_page_preview': true,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['ok'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> sendBoilerAlert({
    required String botToken,
    required String chatId,
    required String eventType, // 'ignition' | 'freeze_warning' | 'disconnect' | 'battery' | 'test'
    required double currentTemp,
    required double targetTemp,
    required bool isHeating,
  }) async {
    final timeStr = DateFormat('HH:mm:ss - dd.MM.yyyy').format(DateTime.now());

    String icon;
    String title;
    String description;

    switch (eventType) {
      case 'ignition':
        icon = '🔥';
        title = 'KOMBİ ATEŞLEMESİ BAŞLADI';
        description = 'Oda sıcaklığı hedefin altına düştü, kombi rölesi çekerek petekleri ısıtmaya başladı.';
        break;
      case 'freeze_warning':
        icon = '❄️⚠️';
        title = 'DONMA TEHLİKESİ UYARISI';
        description = 'Oda sıcaklığı kritik 5.0°C sınırının altına indi! Emniyet ateşlemesi zorlandı.';
        break;
      case 'disconnect':
        icon = '⚠️📡';
        title = 'ESP32 BAĞLANTISI KOPTU';
        description = 'Kombi kontrol modülüyle Wi-Fi üzerinden 15 saniyeden uzun süredir iletişim kurulamıyor.';
        break;
      case 'battery':
        icon = '🪫';
        title = 'DÜŞÜK PİL İKAZI';
        description = 'Oda termostatı bataryası %15 kritik seviyenin altına geriledi. Lütfen pilleri değiştirin.';
        break;
      case 'test':
      default:
        icon = '🤖✅';
        title = 'TERMOBOT BAĞLANTI TESTİ';
        description = 'Telegram bildirim botu entegrasyonu başarıyla doğrulandı. Tüm acil durum uyarıları anında iletilecektir.';
        break;
    }

    final message = '''
<b>$icon TermoBot Akıllı Kombi Bildirimi</b>
━━━━━━━━━━━━━━━━━━━━
<b>Durum:</b> $title
<b>Açıklama:</b> $description

📊 <b>Telemetri Verileri:</b>
• <b>Canlı Oda:</b> ${currentTemp.toStringAsFixed(1)}°C
• <b>Hedef Termostat:</b> ${targetTemp.toStringAsFixed(1)}°C
• <b>Röle Durumu:</b> ${isHeating ? 'AÇIK (Ateşlemede)' : 'KAPALI (Beklemede)'}
• <b>Zaman:</b> <code>$timeStr</code>
━━━━━━━━━━━━━━━━━━━━
<i>TermoBot Kriptografik Güvenlik Motoru</i>
''';

    return sendRawMessage(
      botToken: botToken,
      chatId: chatId,
      text: message,
    );
  }
}
