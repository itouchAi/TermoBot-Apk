import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_settings.dart';
import '../services/haptics_service.dart';
import '../services/sound_synthesis_service.dart';
import 'vault_modal.dart';
import 'google_home_modal.dart';
import 'esp_diagnostics_modal.dart';

class SettingsSheet extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onUpdateSettings;
  final VoidCallback onLaunchSmartDisplay;
  final VoidCallback onTriggerTestCall;
  final VoidCallback onTriggerDisconnectAlert;
  final VoidCallback onTriggerLowBatteryAlert;
  final VoidCallback onResetFactorySettings;
  final VoidCallback? onLaunchScreenSaver;

  const SettingsSheet({
    super.key,
    required this.settings,
    required this.onUpdateSettings,
    required this.onLaunchSmartDisplay,
    required this.onTriggerTestCall,
    required this.onTriggerDisconnectAlert,
    required this.onTriggerLowBatteryAlert,
    required this.onResetFactorySettings,
    this.onLaunchScreenSaver,
  });

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late AppSettings _s;
  String? _expandedSection;

  @override
  void initState() {
    super.initState();
    _s = widget.settings;
  }

  void _toggle(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      _expandedSection = _expandedSection == id ? null : id;
    });
  }

  void _save(AppSettings next) {
    setState(() => _s = next);
    widget.onUpdateSettings(next);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1523),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag indicator
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: Color(0xFFFF6A00), size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Sistem & Donanım Ayarları',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // 11 Settings Sections List
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // 1. Şifreli Kasa & Bildirimler
                _buildSectionCard(
                  id: 'vault',
                  title: '1. Şifreli Kasa & Acil Emniyet',
                  sub: 'AES-256 PIN koruması, Telegram bildirim botu',
                  icon: Icons.lock_outline_rounded,
                  accentColor: const Color(0xFFF59E0B),
                  content: Column(
                    children: [
                      _buildTextField(
                        label: 'Güvenlik Kasa PIN Kodu',
                        initialVal: _s.vaultPin,
                        isObscure: true,
                        onChanged: (val) => _save(_s.copyWith(vaultPin: val)),
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        label: 'Telegram Bot Token',
                        initialVal: _s.telegramToken,
                        onChanged: (val) => _save(_s.copyWith(telegramToken: val)),
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        label: 'Telegram Chat ID',
                        initialVal: _s.telegramChatId,
                        onChanged: (val) => _save(_s.copyWith(telegramChatId: val)),
                      ),
                      const SizedBox(height: 10),
                      _buildSwitch(
                        label: 'Telegram Acil Bildirimleri Aktif',
                        val: _s.telegramAlertsEnabled,
                        onChanged: (v) => _save(_s.copyWith(telegramAlertsEnabled: v)),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          minimumSize: const Size.fromHeight(40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.lock_open_rounded, color: Colors.white, size: 18),
                        label: const Text('Şifreli Kasa PIN Girişi & Test',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) => VaultModal(
                              currentPin: _s.vaultPin,
                              onUpdatePin: (p) => _save(_s.copyWith(vaultPin: p)),
                              telegramToken: _s.telegramToken,
                              telegramChatId: _s.telegramChatId,
                              onUpdateToken: (t) => _save(_s.copyWith(telegramToken: t)),
                              onUpdateChatId: (c) => _save(_s.copyWith(telegramChatId: c)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // 2. Google Home & Asistan
                _buildSectionCard(
                  id: 'google_home',
                  title: '2. Google Home & Sesli Asistan',
                  sub: 'Google Asistan sesli komut köprüsü',
                  icon: Icons.home_rounded,
                  accentColor: const Color(0xFF3B82F6),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSwitch(
                        label: 'Google Home Entegrasyonu Aktif',
                        val: _s.googleHomeEnabled,
                        onChanged: (v) => _save(_s.copyWith(googleHomeEnabled: v)),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        label: 'Cihaz Adı',
                        initialVal: _s.googleHomeDeviceName,
                        onChanged: (val) => _save(_s.copyWith(googleHomeDeviceName: val)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '🎙️ "Hey Google, salon termostatını 22 derece yap"',
                          style: TextStyle(fontSize: 12, color: Colors.blueAccent),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          minimumSize: const Size.fromHeight(40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 18),
                        label: const Text('Matter Eşleştirme Kodunu Yönet',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) => GoogleHomeModal(
                              isEnabled: _s.googleHomeEnabled,
                              onToggleEnabled: (v) => _save(_s.copyWith(googleHomeEnabled: v)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // 3. Smart Display & Ambiyans
                _buildSectionCard(
                  id: 'smart_display',
                  title: '3. Smart Display & Ambiyans Modu',
                  sub: 'Tam ekran dijital saat ve termostat ambiyansı',
                  icon: Icons.tv_rounded,
                  accentColor: const Color(0xFF8B5CF6),
                  content: Column(
                    children: [
                      _buildSwitch(
                        label: 'Ekran Koruyucu Otomatik Başlasın',
                        val: _s.smartDisplayEnabled,
                        onChanged: (v) => _save(_s.copyWith(smartDisplayEnabled: v)),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                        label: const Text('Ambiyans Modunu Şimdi Başlat',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onLaunchSmartDisplay();
                        },
                      ),
                    ],
                  ),
                ),

                // 4. Bildirim Ayarları & Otomasyon
                _buildSectionCard(
                  id: 'notifications',
                  title: '4. Bildirimler & Otomasyon',
                  sub: '3 saatlik hava raporu, düşük pil & bağlantı alarmı',
                  icon: Icons.notifications_active_rounded,
                  accentColor: const Color(0xFFFF6A00),
                  content: Column(
                    children: [
                      _buildSwitch(
                        label: '3 Saatlik Periyodik Durum Bildirimi',
                        val: _s.periodicWeatherNotifs,
                        onChanged: (v) => _save(_s.copyWith(periodicWeatherNotifs: v)),
                      ),
                      _buildSwitch(
                        label: 'Kritik Su Basıncı / Donma Koruması',
                        val: _s.criticalAlertsEnabled,
                        onChanged: (v) => _save(_s.copyWith(criticalAlertsEnabled: v)),
                      ),
                      _buildSwitch(
                        label: 'Düşük Pil Uyarısı (< %20)',
                        val: _s.lowBatteryAlertsEnabled,
                        onChanged: (v) => _save(_s.copyWith(lowBatteryAlertsEnabled: v)),
                      ),
                      _buildSwitch(
                        label: 'Kombi Bağlantı Kopması Uyarısı',
                        val: _s.disconnectAlertsEnabled,
                        onChanged: (v) => _save(_s.copyWith(disconnectAlertsEnabled: v)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFDC2626)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: widget.onTriggerDisconnectAlert,
                              child: const Text('⚠️ Kopma Testi', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFF59E0B)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: widget.onTriggerLowBatteryAlert,
                              child: const Text('🪫 Pil Testi', style: TextStyle(fontSize: 11, color: Colors.amberAccent)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 5. Haptik Titreşim & Sentetik Ses Motoru (Madde 13, 14, 15)
                _buildSectionCard(
                  id: 'haptics',
                  title: '5. Haptik & Sentetik Ses Motoru',
                  sub: 'Mekanik kadran klikleri, röle thud vuruşu ve maskot sesleri',
                  icon: Icons.volume_up_rounded,
                  accentColor: const Color(0xFF10B981),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSwitch(
                        label: 'Dokunsal Haptik Titreşim Motoru',
                        val: _s.hapticsEnabled,
                        onChanged: (v) {
                          HapticsService.setEnabled(v);
                          _save(_s.copyWith(hapticsEnabled: v));
                        },
                      ),
                      _buildSwitch(
                        label: 'Sentetik Mekanik Ses Efektleri (Web Audio)',
                        val: SoundSynthesisService.isEnabled,
                        onChanged: (v) {
                          SoundSynthesisService.setEnabled(v);
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Titreşim Yoğunluğu:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ['light', 'medium', 'heavy'].map((strength) {
                          final isSel = _s.hapticStrength == strength;
                          return ChoiceChip(
                            label: Text(strength.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            selected: isSel,
                            selectedColor: const Color(0xFF10B981),
                            onSelected: (val) {
                              if (strength == 'light') HapticsService.trigger(HapticFeedbackType.light, force: true);
                              if (strength == 'medium') HapticsService.trigger(HapticFeedbackType.medium, force: true);
                              if (strength == 'heavy') HapticsService.trigger(HapticFeedbackType.heavy, force: true);
                              _save(_s.copyWith(hapticStrength: strength));
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Canlı Ses & Titreşim Testleri:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.touch_app_rounded, size: 14, color: Color(0xFFFBBF24)),
                            label: const Text('Kadran Kliki', style: TextStyle(fontSize: 10, color: Colors.white)),
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            onPressed: () => SoundSynthesisService.playDialTick(),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.flash_on_rounded, size: 14, color: Color(0xFFFF6A00)),
                            label: const Text('Röle Ateşleme Thud', style: TextStyle(fontSize: 10, color: Colors.white)),
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            onPressed: () => SoundSynthesisService.playRelayClick(isEngaged: true),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.music_note_rounded, size: 14, color: Color(0xFF38BDF8)),
                            label: const Text('Maskot Fanfarı', style: TextStyle(fontSize: 10, color: Colors.white)),
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            onPressed: () => SoundSynthesisService.playMascotSound(MascotSoundType.happy),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFFB7185)),
                            label: const Text('İkaz Sireni', style: TextStyle(fontSize: 10, color: Colors.white)),
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            onPressed: () => SoundSynthesisService.playWarningAlert(WarningSoundType.connection),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 6. Açılış Seremonisi (Boot Efekti)
                _buildSectionCard(
                  id: 'boot_splash',
                  title: '6. Açılış Seremonisi (Boot Efekti)',
                  sub: 'TermoBot holografik açılış seremonisi',
                  icon: Icons.auto_awesome_rounded,
                  accentColor: const Color(0xFF00E5FF),
                  content: _buildSwitch(
                    label: 'Başlangıç Animasyonunu Göster',
                    val: _s.startupSplashEnabled,
                    onChanged: (v) => _save(_s.copyWith(startupSplashEnabled: v)),
                  ),
                ),

                // 7. Sanal Asistan & Sevimli Maskot
                _buildSectionCard(
                  id: 'mascot',
                  title: '7. Sanal Asistan & Sevimli Maskot',
                  sub: 'Ana ekranda canlı zıplayan interaktif 3D maskot',
                  icon: Icons.smart_toy_rounded,
                  accentColor: const Color(0xFFEC4899),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSwitch(
                        label: 'Maskotu Göster',
                        val: _s.mascotEnabled,
                        onChanged: (v) => _save(_s.copyWith(mascotEnabled: v)),
                      ),
                      _buildSwitch(
                        label: 'Maskot Ses Efektleri',
                        val: _s.mascotSoundsEnabled,
                        onChanged: (v) => _save(_s.copyWith(mascotSoundsEnabled: v)),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Aktif Maskot Karakteri:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildMascotChoicePill('termobot', '🤖 TermoBot', const Color(0xFF38BDF8)),
                          const SizedBox(width: 6),
                          _buildMascotChoicePill('flamey', '🔥 Flamey', const Color(0xFFFF8C32)),
                          const SizedBox(width: 6),
                          _buildMascotChoicePill('frosty', '❄️ Frosty', const Color(0xFF93C5FD)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEC4899),
                          minimumSize: const Size.fromHeight(42),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.nightlight_round, color: Colors.white, size: 18),
                        label: const Text(
                          'Maskot Ekran Koruyucuyu Başlat',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.pop(context);
                          widget.onLaunchScreenSaver?.call();
                        },
                      ),
                    ],
                  ),
                ),

                // 8. AI Sesli Telefon Araması
                _buildSectionCard(
                  id: 'voice_call',
                  title: '8. AI Sesli Telefon Araması',
                  sub: 'Ateşleme ve acil durumda tam ekran arama',
                  icon: Icons.phone_in_talk_rounded,
                  accentColor: const Color(0xFF22C55E),
                  content: Column(
                    children: [
                      _buildSwitch(
                        label: 'Sesli Arama Modülü Aktif',
                        val: _s.voiceCallEnabled,
                        onChanged: (v) => _save(_s.copyWith(voiceCallEnabled: v)),
                      ),
                      _buildSwitch(
                        label: 'Kombi Ateşlendiğinde Otomatik Ara',
                        val: _s.autoCallOnIgnition,
                        onChanged: (v) => _save(_s.copyWith(autoCallOnIgnition: v)),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.ring_volume_rounded, color: Colors.white),
                        label: const Text('Sesli Aramayı Şimdi Test Et',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onTriggerTestCall();
                        },
                      ),
                    ],
                  ),
                ),

                // 9. ESP32 Donanım Güvenlik & Günlüğü
                _buildSectionCard(
                  id: 'esp_hardware',
                  title: '9. ESP32 Donanım & IP Köprüsü',
                  sub: 'Yerel ağdaki ESP32 röle bağlantı parametreleri ve tanılaması',
                  icon: Icons.developer_board_rounded,
                  accentColor: const Color(0xFF06B6D4),
                  content: Column(
                    children: [
                      _buildTextField(
                        label: 'ESP32 Yerel IP Adresi',
                        initialVal: _s.espIp,
                        onChanged: (v) => _save(_s.copyWith(espIp: v)),
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        label: 'İletişim Portu (Örn: 80)',
                        initialVal: _s.espPort.toString(),
                        onChanged: (v) => _save(_s.copyWith(espPort: int.tryParse(v) ?? 80)),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0891B2),
                          minimumSize: const Size.fromHeight(42),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.troubleshoot_rounded, color: Colors.white, size: 18),
                        label: const Text(
                          'Donanım Tanılama & Röle Stres Testi',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EspDiagnosticsModal(
                                espIp: _s.espIp,
                                espPort: _s.espPort,
                                isConnected: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // 10. Bulut Ayarları
                _buildSectionCard(
                  id: 'cloud',
                  title: '10. Bulut Senkronizasyonu',
                  sub: 'Firebase Realtime Database köprüsü',
                  icon: Icons.cloud_done_rounded,
                  accentColor: const Color(0xFF6366F1),
                  content: Column(
                    children: [
                      _buildTextField(
                        label: 'Firebase DB URL',
                        initialVal: _s.firebaseDbUrl,
                        onChanged: (v) => _save(_s.copyWith(firebaseDbUrl: v)),
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        label: 'Firebase API Key',
                        initialVal: _s.firebaseApiKey,
                        onChanged: (v) => _save(_s.copyWith(firebaseApiKey: v)),
                      ),
                    ],
                  ),
                ),

                // 11. Fabrika Ayarlarına Sıfırla
                _buildSectionCard(
                  id: 'reset',
                  title: '11. Fabrika Ayarlarına Sıfırla',
                  sub: 'Tüm yerel ayarları ve kasa verilerini sıfırla',
                  icon: Icons.delete_forever_rounded,
                  accentColor: const Color(0xFFEF4444),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'DİKKAT: Tüm şifreli kasa, donanım IP ve tercihler temizlenip tertemiz kurulum haline getirilir.',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.restart_alt_rounded, color: Colors.white),
                        label: const Text('Fabrika Ayarlarına Sıfırla',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          widget.onResetFactorySettings();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String id,
    required String title,
    required String sub,
    required IconData icon,
    required Color accentColor,
    required Widget content,
  }) {
    final isOpen = _expandedSection == id;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161F33),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOpen ? accentColor.withOpacity(0.5) : Colors.white10,
          width: isOpen ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => _toggle(id),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              sub,
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
            trailing: Icon(
              isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: Colors.white54,
            ),
          ),
          if (isOpen)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 4),
              child: content,
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String initialVal,
    required ValueChanged<String> onChanged,
    bool isObscure = false,
  }) {
    return TextFormField(
      initialValue: initialVal,
      obscureText: isObscure,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF0F1523),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildSwitch({
    required String label,
    required bool val,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.white),
            ),
          ),
          Switch.adaptive(
            value: val,
            activeColor: const Color(0xFFFF6A00),
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMascotChoicePill(String id, String label, Color accent) {
    final isSel = _s.mascotType == id;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          _save(_s.copyWith(mascotType: id));
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? accent.withOpacity(0.25) : const Color(0xFF0F1523),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSel ? accent : Colors.white12,
              width: isSel ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                color: isSel ? Colors.white : Colors.white60,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
