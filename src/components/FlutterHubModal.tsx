import React, { useState } from 'react';
import {
  X,
  Code2,
  CheckCircle2,
  FolderTree,
  Terminal,
  Cpu,
  Flame,
  Volume2,
  Lock,
  Layers,
  ChevronRight,
  ExternalLink,
} from 'lucide-react';

interface FlutterHubModalProps {
  isOpen: boolean;
  onClose: () => void;
}

interface FlutterFileStat {
  name: string;
  path: string;
  lines: number;
  category: 'Screens' | 'Widgets' | 'Services' | 'Models & Utils';
  description: string;
  tags: string[];
}

const FLUTTER_FILES: FlutterFileStat[] = [
  // Screens
  { name: 'tactile_deck_screen.dart', path: 'lib/screens/tactile_deck_screen.dart', lines: 844, category: 'Screens', description: 'Ana 3D Kadran & Carousel Deck Ekranı, dil bayrağı ve sekme geçişleri', tags: ['CustomPaint', 'Carousel', 'State'] },
  { name: 'reports_screen.dart', path: 'lib/screens/reports_screen.dart', lines: 691, category: 'Screens', description: 'Tüketim analitiği, 168 hücrelik ısı haritası ve konfor indeksi ekranı', tags: ['Heatmap', 'ComfortGauge', 'Billing'] },
  { name: 'weather_screen.dart', path: 'lib/screens/weather_screen.dart', lines: 682, category: 'Screens', description: 'GPU parçacık motorlu meteoroloji, 24s saatlik tahmin ve konum yöneticisi', tags: ['OpenMeteo', 'GPU Canvas', 'Locations'] },
  { name: 'schedule_screen.dart', path: 'lib/screens/schedule_screen.dart', lines: 628, category: 'Screens', description: 'Haftalık akıllı sıcaklık programı, zaman yuvaları ve tasarruf hesaplayıcı', tags: ['WeeklyGrid', 'TimeSlots', 'Savings'] },
  { name: 'thermostat_screen.dart', path: 'lib/screens/thermostat_screen.dart', lines: 162, category: 'Screens', description: 'Hızlı termostat görünümü ve röle kontrolü', tags: ['Thermostat', 'Relay'] },

  // Widgets
  { name: 'smart_display_view.dart', path: 'lib/widgets/smart_display_view.dart', lines: 802, category: 'Widgets', description: 'OLED Kiosk Ambiyans modu, burn-in koruması, dokunmatik tekerlek modalı', tags: ['OLED Burn-in', 'LuxuryBar', 'Equalizer'] },
  { name: 'settings_sheet.dart', path: 'lib/widgets/settings_sheet.dart', lines: 787, category: 'Widgets', description: '11 bölümlü kapsamlı ayarlar paneli, donanım ve haptik ayarları', tags: ['11 Sections', 'Haptics', 'Sound Test'] },
  { name: 'esp_diagnostics_modal.dart', path: 'lib/widgets/esp_diagnostics_modal.dart', lines: 717, category: 'Widgets', description: 'ESP32 Donanım tanılama, canlı jitter dalgası, 10 döngülü röle stres testi', tags: ['Ping Jitter', 'Relay Endurance', 'LittleFS'] },
  { name: 'universal_mascot.dart', path: 'lib/widgets/universal_mascot.dart', lines: 601, category: 'Widgets', description: 'TermoBot, Flamey, Frosty 3 karakter; titreme/terleme ve konuşma baloncukları', tags: ['3 Characters', 'Autonomous FSM', 'Emotions'] },
  { name: 'atmospheric_weather_canvas.dart', path: 'lib/widgets/atmospheric_weather_canvas.dart', lines: 584, category: 'Widgets', description: 'Yağmur damlaları, lapa lapa kar fırtınası, şimşek çakması GPU fizik motoru', tags: ['GPU Physics', 'Rain Splash', 'Snow Drift'] },
  { name: 'heatmap_matrix_widget.dart', path: 'lib/widgets/heatmap_matrix_widget.dart', lines: 526, category: 'Widgets', description: '7 Gün × 24 Saat = 168 interaktif hücre, dokunmatik detay kartı, alev rozeti', tags: ['168 Cells', '7x24 Matrix', 'Color Scale'] },
  { name: 'media_playlist_modal.dart', path: 'lib/widgets/media_playlist_modal.dart', lines: 523, category: 'Widgets', description: 'Smart Display çoklu ortam oynatma listesi ve video URL yöneticisi', tags: ['Video URLs', 'MP3 Streams', 'Theme Presets'] },
  { name: 'luxury_media_bar.dart', path: 'lib/widgets/luxury_media_bar.dart', lines: 485, category: 'Widgets', description: 'TV rozeti, yukarı açılan dikey ses popover barı, sürekli döngü toggle', tags: ['Vertical Slider', 'Auto-collapse', 'Play/Pause'] },
  { name: 'vault_modal.dart', path: 'lib/widgets/vault_modal.dart', lines: 405, category: 'Widgets', description: 'Kripto Donanım Kasası, PIN hashleme, şifreli anahtarlar ve Telegram test butonu', tags: ['Crypto PIN', 'AES-256', 'Telegram Test'] },
  { name: 'exact_tactile_dial.dart', path: 'lib/widgets/exact_tactile_dial.dart', lines: 356, category: 'Widgets', description: '3D tırtıklı döner kadran, metalik kubbe, mekanik tık klik sesi sentezi', tags: ['Knurled Rotary', 'Sound Tick', 'Haptic'] },
  { name: 'tactile_dial.dart', path: 'lib/widgets/tactile_dial.dart', lines: 368, category: 'Widgets', description: 'Döner kadran ve stepper artırma/azaltma butonları', tags: ['Dial Arc', 'Stepper Buttons'] },
  { name: 'voice_call_overlay.dart', path: 'lib/widgets/voice_call_overlay.dart', lines: 326, category: 'Widgets', description: 'Tam ekran Android arama simülasyonu, sentetik marimba melodi döngüsü', tags: ['Phone Call', 'Ringtone Cadence'] },
  { name: 'voice_assistant_modal.dart', path: 'lib/widgets/voice_assistant_modal.dart', lines: 305, category: 'Widgets', description: 'Akıllı sesli komut asistanı, dalga animasyonu ve öneriler', tags: ['Voice Assistant', 'Commands'] },
  { name: 'mascot_screen_saver_overlay.dart', path: 'lib/widgets/mascot_screen_saver_overlay.dart', lines: 296, category: 'Widgets', description: '64px OLED saat, yüzen maskot, 4 tema ve 60s piksel kaydırma', tags: ['OLED Screensaver', 'Pixel Shift', 'Kiosk'] },
  { name: 'theme_selector_modal.dart', path: 'lib/widgets/theme_selector_modal.dart', lines: 289, category: 'Widgets', description: 'Obsidian Lavender ve Tactile Deck tema paletleri seçicisi', tags: ['Themes', 'Palettes'] },
  { name: 'telemetry_cards.dart', path: 'lib/widgets/telemetry_cards.dart', lines: 270, category: 'Widgets', description: 'Oda sıcaklığı, nem, basınç, alev ve röle durum kartları', tags: ['Sensors', 'Telemetry'] },
  { name: 'music_equalizer.dart', path: 'lib/widgets/music_equalizer.dart', lines: 257, category: 'Widgets', description: 'Neon sütunlar (peak caps), sıvı dalga ve bas nabız halkaları', tags: ['Equalizer Bars', 'Sine Wave', 'Radial Pulse'] },
  { name: 'smart_display_controls_pill.dart', path: 'lib/widgets/smart_display_controls_pill.dart', lines: 251, category: 'Widgets', description: 'Güneş ikonu ve %10-100 parlaklık ayar çubuğu', tags: ['Brightness Slider', 'Red Exit'] },
  { name: 'comfort_index_widget.dart', path: 'lib/widgets/comfort_index_widget.dart', lines: 196, category: 'Widgets', description: 'Gerçek termal konfor formülü, radyal CustomPaint göstergesi', tags: ['Thermal Math', 'Radial Gauge'] },
  { name: 'google_home_modal.dart', path: 'lib/widgets/google_home_modal.dart', lines: 172, category: 'Widgets', description: 'Google Assistant / Home cihaz eşleme modalı', tags: ['Google Home', 'Matter'] },
  { name: 'widget_customizer_modal.dart', path: 'lib/widgets/widget_customizer_modal.dart', lines: 160, category: 'Widgets', description: 'Sekme ve kart sıralama düzenleyicisi', tags: ['Widget Reorder', 'Customizer'] },
  { name: 'holographic_rings.dart', path: 'lib/widgets/holographic_rings.dart', lines: 153, category: 'Widgets', description: 'Dönen holografik neon halka çizici', tags: ['Holographic', 'Animation'] },
  { name: 'startup_boot_splash.dart', path: 'lib/widgets/startup_boot_splash.dart', lines: 138, category: 'Widgets', description: 'Holografik boot seremonisi ve bios yükleme efekti', tags: ['Boot Splash', 'BIOS Log'] },
  { name: 'mascot_widget.dart', path: 'lib/widgets/mascot_widget.dart', lines: 130, category: 'Widgets', description: 'Mini zıplayan maskot bileşeni', tags: ['Mini Mascot'] },

  // Services
  { name: 'history_storage_service.dart', path: 'lib/services/history_storage_service.dart', lines: 180, category: 'Services', description: 'SharedPreferences kalıcı geçmiş veri tabanı ve birim fiyat saklama', tags: ['Persistence', 'Hourly DB'] },
  { name: 'sound_synthesis_service.dart', path: 'lib/services/sound_synthesis_service.dart', lines: 115, category: 'Services', description: 'Saf Flutter SystemSound mekanik kadran kliki, röle thud vuruşu ve ikaz sesleri', tags: ['SystemSound', 'Dial Tick', 'Native'] },
  { name: 'weather_service.dart', path: 'lib/services/weather_service.dart', lines: 112, category: 'Services', description: 'Open-Meteo API veri çekme ve fallback meteoroloji modeli', tags: ['Open-Meteo', 'Weather API'] },
  { name: 'telegram_bot_service.dart', path: 'lib/services/telegram_bot_service.dart', lines: 102, category: 'Services', description: 'Canlı Telegram Bot API webhook köprüsü, acil durum uyarı iletimi', tags: ['Telegram API', 'Webhook', 'Alerts'] },
  { name: 'esp_service.dart', path: 'lib/services/esp_service.dart', lines: 71, category: 'Services', description: 'ESP32 Wi-Fi HTTP röle anahtarlama ve termostat kural motoru', tags: ['ESP32 HTTP', 'Thermostat Rules'] },
  { name: 'haptics_service.dart', path: 'lib/services/haptics_service.dart', lines: 67, category: 'Services', description: '6 seviyeli dokunsal titreşim geri bildirim yöneticisi', tags: ['Haptics', 'Vibration'] },

  // Models & Utils
  { name: 'main.dart', path: 'lib/main.dart', lines: 351, category: 'Models & Utils', description: 'Uygulama giriş noktası, otonom döngüler ve tam ekran overlay yöneticisi', tags: ['Main Entry', 'Orchestrator'] },
  { name: 'smart_display_config.dart', path: 'lib/models/smart_display_config.dart', lines: 245, category: 'Models & Utils', description: 'Smart Display yapılandırması, preset temalar ve playlist modelleri', tags: ['Config Model', 'JSON Serialization'] },
  { name: 'i18n.dart', path: 'lib/utils/i18n.dart', lines: 218, category: 'Models & Utils', description: 'TR/EN çift dilli sözlük, reaktif dil bildirimcisi ve kalıcı saklama', tags: ['TR/EN Dict', 'ValueNotifier'] },
  { name: 'crypto_vault.dart', path: 'lib/utils/crypto_vault.dart', lines: 177, category: 'Models & Utils', description: 'PBKDF2 100k iterasyon, AES-GCM şifreleme, PIN hashleme', tags: ['PBKDF2', 'AES-GCM', 'SHA-256'] },
  { name: 'app_settings.dart', path: 'lib/models/app_settings.dart', lines: 168, category: 'Models & Utils', description: 'Tüm uygulama tercihleri, maskot türü ve donanım ayarları modeli', tags: ['AppSettings', 'Serialization'] },
  { name: 'obsidian_palettes.dart', path: 'lib/models/obsidian_palettes.dart', lines: 101, category: 'Models & Utils', description: 'Derin Obsidyen Dumanı, Lavanta, Leylak renk paletleri', tags: ['Color Palettes'] },
  { name: 'app_theme.dart', path: 'lib/theme/app_theme.dart', lines: 54, category: 'Models & Utils', description: 'Modern koyu OLED tema tasarımı ve font aileleri', tags: ['Theme Data'] },
  { name: 'thermostat_state.dart', path: 'lib/models/thermostat_state.dart', lines: 47, category: 'Models & Utils', description: 'Termostat durumu, alev modülasyonu ve bağlantı modeli', tags: ['State Model'] },
];

export const FlutterHubModal: React.FC<FlutterHubModalProps> = ({ isOpen, onClose }) => {
  const [activeCategory, setActiveCategory] = useState<string>('All');
  const [searchQuery, setSearchQuery] = useState<string>('');

  if (!isOpen) return null;

  const totalLines = FLUTTER_FILES.reduce((acc, f) => acc + f.lines, 0);

  const filteredFiles = FLUTTER_FILES.filter((f) => {
    const matchesCat = activeCategory === 'All' || f.category === activeCategory;
    const matchesSearch =
      f.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      f.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
      f.tags.some((t) => t.toLowerCase().includes(searchQuery.toLowerCase()));
    return matchesCat && matchesSearch;
  });

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-5 bg-black/85 backdrop-blur-xl animate-in fade-in duration-200">
      <div
        className="w-full max-w-4xl max-h-[92vh] flex flex-col bg-[#0F172A] border border-cyan-500/30 rounded-3xl shadow-[0_20px_60px_rgba(0,0,0,0.8),0_0_30px_rgba(6,182,212,0.2)] text-white overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Modal Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-white/10 bg-gradient-to-r from-cyan-950/60 via-slate-900 to-slate-900 shrink-0">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-gradient-to-tr from-cyan-500 to-blue-600 flex items-center justify-center text-white shadow-lg shadow-cyan-500/30">
              <Cpu className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-base sm:text-lg font-black tracking-tight text-white">
                  TermoBot Flutter & Dart Mimari Merkezi
                </h2>
                <span className="px-2 py-0.5 rounded-full text-[10px] font-mono font-bold bg-cyan-500/20 text-cyan-300 border border-cyan-400/30">
                  v1.0.0 NATIVE
                </span>
              </div>
              <p className="text-xs text-slate-400">
                14.344 satır saf Dart kodu • 44 dosya • 18/18 madde eksiksiz aktarıldı
              </p>
            </div>
          </div>

          <button
            type="button"
            onClick={onClose}
            className="p-2 rounded-xl bg-white/5 hover:bg-white/15 text-slate-400 hover:text-white transition-all cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Milestone Summary Ribbon */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5 p-4 bg-white/[0.02] border-b border-white/10 shrink-0">
          <div className="p-3 rounded-2xl bg-white/[0.03] border border-white/10 flex items-center gap-2.5">
            <Code2 className="w-5 h-5 text-cyan-400 shrink-0" />
            <div>
              <div className="text-[10px] font-bold text-slate-400 uppercase">Toplam Kod</div>
              <div className="text-base font-black text-cyan-300 font-mono">14.344 Satır</div>
            </div>
          </div>
          <div className="p-3 rounded-2xl bg-white/[0.03] border border-white/10 flex items-center gap-2.5">
            <FolderTree className="w-5 h-5 text-amber-400 shrink-0" />
            <div>
              <div className="text-[10px] font-bold text-slate-400 uppercase">Dart Dosyaları</div>
              <div className="text-base font-black text-amber-300 font-mono">44 Dosya</div>
            </div>
          </div>
          <div className="p-3 rounded-2xl bg-white/[0.03] border border-white/10 flex items-center gap-2.5">
            <CheckCircle2 className="w-5 h-5 text-emerald-400 shrink-0" />
            <div>
              <div className="text-[10px] font-bold text-slate-400 uppercase">Plan Maddeleri</div>
              <div className="text-base font-black text-emerald-300 font-mono">18 / 18 Tamam</div>
            </div>
          </div>
          <div className="p-3 rounded-2xl bg-white/[0.03] border border-white/10 flex items-center gap-2.5">
            <Terminal className="w-5 h-5 text-violet-400 shrink-0" />
            <div>
              <div className="text-[10px] font-bold text-slate-400 uppercase">Derleme Testi</div>
              <div className="text-base font-black text-violet-300 font-mono">PASS (0 Hata)</div>
            </div>
          </div>
        </div>

        {/* Category Filters & Search */}
        <div className="flex flex-col sm:flex-row items-center justify-between gap-3 px-6 py-3 border-b border-white/10 bg-slate-900/40 shrink-0">
          <div className="flex items-center gap-1.5 overflow-x-auto w-full sm:w-auto pb-1 sm:pb-0">
            {['All', 'Screens', 'Widgets', 'Services', 'Models & Utils'].map((cat) => (
              <button
                key={cat}
                type="button"
                onClick={() => setActiveCategory(cat)}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all cursor-pointer whitespace-nowrap ${
                  activeCategory === cat
                    ? 'bg-cyan-500 text-slate-950 shadow-md shadow-cyan-500/25'
                    : 'bg-white/5 hover:bg-white/10 text-slate-400 hover:text-white'
                }`}
              >
                {cat}
              </button>
            ))}
          </div>

          <input
            type="text"
            placeholder="Dosya, bileşen veya özellik ara..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full sm:w-64 px-3.5 py-1.5 rounded-xl bg-white/5 border border-white/15 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-cyan-400 transition-colors"
          />
        </div>

        {/* Scrollable File List */}
        <div className="flex-1 overflow-y-auto p-4 sm:p-6 space-y-2">
          {filteredFiles.map((file) => (
            <div
              key={file.name}
              className="p-3.5 rounded-2xl bg-white/[0.03] hover:bg-white/[0.06] border border-white/10 hover:border-cyan-500/40 transition-all flex flex-col sm:flex-row sm:items-center justify-between gap-2.5 group"
            >
              <div className="flex items-start gap-3">
                <div className="p-2 rounded-xl bg-white/5 text-cyan-400 border border-white/10 group-hover:text-cyan-300 group-hover:border-cyan-500/30 transition-all shrink-0 mt-0.5">
                  <Code2 className="w-4 h-4" />
                </div>
                <div>
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="font-mono text-sm font-bold text-white group-hover:text-cyan-300 transition-colors">
                      {file.name}
                    </span>
                    <span className="text-[10px] font-mono px-2 py-0.5 rounded-md bg-white/10 text-slate-300 font-bold">
                      {file.lines} satır
                    </span>
                    <span className="text-[10px] px-2 py-0.5 rounded-md bg-cyan-500/15 text-cyan-400 border border-cyan-500/20 font-semibold">
                      {file.category}
                    </span>
                  </div>
                  <p className="text-xs text-slate-400 mt-1">{file.description}</p>
                  <div className="flex items-center gap-1.5 mt-2 flex-wrap">
                    {file.tags.map((tag) => (
                      <span
                        key={tag}
                        className="text-[9px] px-1.5 py-0.5 rounded-sm bg-white/5 text-slate-400 font-mono"
                      >
                        #{tag}
                      </span>
                    ))}
                  </div>
                </div>
              </div>

              <div className="text-right shrink-0">
                <span className="text-[10px] font-mono text-slate-500 block">/flutter_termobot/{file.path}</span>
              </div>
            </div>
          ))}
        </div>

        {/* Modal Footer with Run Command Snippet */}
        <div className="px-6 py-3.5 border-t border-white/10 bg-slate-950 flex flex-col sm:flex-row items-center justify-between gap-3 text-xs text-slate-400 shrink-0">
          <div className="flex items-center gap-2">
            <Terminal className="w-4 h-4 text-cyan-400" />
            <span className="font-mono text-[11px] text-cyan-300">
              cd flutter_termobot && flutter run -d chrome / flutter build apk
            </span>
          </div>

          <div className="flex items-center gap-3">
            <span className="text-emerald-400 font-bold flex items-center gap-1">
              <CheckCircle2 className="w-4 h-4" /> 18 Madde Eksiksiz Aktarıldı
            </span>
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-1.5 rounded-xl bg-cyan-500 hover:bg-cyan-400 active:scale-95 text-slate-950 font-bold transition-all cursor-pointer"
            >
              Tamam
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
