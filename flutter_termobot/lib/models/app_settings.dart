class AppSettings {
  // 1. Şifreli Kasa & Bildirimler
  String vaultPin;
  bool isVaultLocked;
  String telegramToken;
  String telegramChatId;
  bool telegramAlertsEnabled;

  // 2. Google Home & Asistan
  bool googleHomeEnabled;
  String googleHomeDeviceName;

  // 3. Smart Display & Ambiyans
  bool smartDisplayEnabled;
  String smartDisplayTheme; // 'ambient_glow' | 'minimal_clock' | 'neon_deck'
  int screensaverTimeoutSec;

  // 4. Bildirim Ayarları & Otomasyon
  bool periodicWeatherNotifs;
  bool criticalAlertsEnabled;
  bool lowBatteryAlertsEnabled;
  bool disconnectAlertsEnabled;

  // 5. Haptik Titreşim & Dokunma
  bool hapticsEnabled;
  String hapticStrength; // 'light' | 'medium' | 'heavy'

  // 6. Açılış Seremonisi (Boot Efekti)
  bool startupSplashEnabled;
  int splashDurationMs;

  // 7. Sanal Asistan & Sevimli Maskot
  bool mascotEnabled;
  String mascotEmotion; // 'happy' | 'warming' | 'sleepy' | 'idle'
  bool mascotSoundsEnabled;

  // 8. AI Sesli Telefon Araması
  bool voiceCallEnabled;
  bool autoCallOnIgnition;
  bool autoCallOnLowTemp;
  String callIncomingNumber;

  // 9. ESP32 Donanım Güvenlik & Günlüğü
  String espIp;
  int espPort;
  int pollIntervalSec;
  bool espAutoReconnect;

  // 10. Bulut Ayarları
  String firebaseDbUrl;
  String firebaseApiKey;
  bool isCloudSyncActive;

  // Tema Tercihi
  String activeTheme; // 'tactile_deck' | 'obsidian_lavender' | 'cyber_glass'

  AppSettings({
    this.vaultPin = '1234',
    this.isVaultLocked = false,
    this.telegramToken = '',
    this.telegramChatId = '',
    this.telegramAlertsEnabled = true,
    this.googleHomeEnabled = true,
    this.googleHomeDeviceName = 'Salon Kombi Termostatı',
    this.smartDisplayEnabled = true,
    this.smartDisplayTheme = 'neon_deck',
    this.screensaverTimeoutSec = 60,
    this.periodicWeatherNotifs = true,
    this.criticalAlertsEnabled = true,
    this.lowBatteryAlertsEnabled = true,
    this.disconnectAlertsEnabled = true,
    this.hapticsEnabled = true,
    this.hapticStrength = 'medium',
    this.startupSplashEnabled = true,
    this.splashDurationMs = 2400,
    this.mascotEnabled = true,
    this.mascotEmotion = 'happy',
    this.mascotSoundsEnabled = true,
    this.voiceCallEnabled = true,
    this.autoCallOnIgnition = true,
    this.autoCallOnLowTemp = true,
    this.callIncomingNumber = '+90 850 300 00 24',
    this.espIp = '192.168.1.150',
    this.espPort = 80,
    this.pollIntervalSec = 3,
    this.espAutoReconnect = true,
    this.firebaseDbUrl = 'https://kombi-kontrol-default-rtdb.firebaseio.com',
    this.firebaseApiKey = 'AIzaSyDMULZx8TS0HuDMlxKzQ6BixW6jXJzJ55c',
    this.isCloudSyncActive = true,
    this.activeTheme = 'tactile_deck',
  });

  AppSettings copyWith({
    String? vaultPin,
    bool? isVaultLocked,
    String? telegramToken,
    String? telegramChatId,
    bool? telegramAlertsEnabled,
    bool? googleHomeEnabled,
    String? googleHomeDeviceName,
    bool? smartDisplayEnabled,
    String? smartDisplayTheme,
    int? screensaverTimeoutSec,
    bool? periodicWeatherNotifs,
    bool? criticalAlertsEnabled,
    bool? lowBatteryAlertsEnabled,
    bool? disconnectAlertsEnabled,
    bool? hapticsEnabled,
    String? hapticStrength,
    bool? startupSplashEnabled,
    int? splashDurationMs,
    bool? mascotEnabled,
    String? mascotEmotion,
    bool? mascotSoundsEnabled,
    bool? voiceCallEnabled,
    bool? autoCallOnIgnition,
    bool? autoCallOnLowTemp,
    String? callIncomingNumber,
    String? espIp,
    int? espPort,
    int? pollIntervalSec,
    bool? espAutoReconnect,
    String? firebaseDbUrl,
    String? firebaseApiKey,
    bool? isCloudSyncActive,
    String? activeTheme,
  }) {
    return AppSettings(
      vaultPin: vaultPin ?? this.vaultPin,
      isVaultLocked: isVaultLocked ?? this.isVaultLocked,
      telegramToken: telegramToken ?? this.telegramToken,
      telegramChatId: telegramChatId ?? this.telegramChatId,
      telegramAlertsEnabled: telegramAlertsEnabled ?? this.telegramAlertsEnabled,
      googleHomeEnabled: googleHomeEnabled ?? this.googleHomeEnabled,
      googleHomeDeviceName: googleHomeDeviceName ?? this.googleHomeDeviceName,
      smartDisplayEnabled: smartDisplayEnabled ?? this.smartDisplayEnabled,
      smartDisplayTheme: smartDisplayTheme ?? this.smartDisplayTheme,
      screensaverTimeoutSec: screensaverTimeoutSec ?? this.screensaverTimeoutSec,
      periodicWeatherNotifs: periodicWeatherNotifs ?? this.periodicWeatherNotifs,
      criticalAlertsEnabled: criticalAlertsEnabled ?? this.criticalAlertsEnabled,
      lowBatteryAlertsEnabled: lowBatteryAlertsEnabled ?? this.lowBatteryAlertsEnabled,
      disconnectAlertsEnabled: disconnectAlertsEnabled ?? this.disconnectAlertsEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      hapticStrength: hapticStrength ?? this.hapticStrength,
      startupSplashEnabled: startupSplashEnabled ?? this.startupSplashEnabled,
      splashDurationMs: splashDurationMs ?? this.splashDurationMs,
      mascotEnabled: mascotEnabled ?? this.mascotEnabled,
      mascotEmotion: mascotEmotion ?? this.mascotEmotion,
      mascotSoundsEnabled: mascotSoundsEnabled ?? this.mascotSoundsEnabled,
      voiceCallEnabled: voiceCallEnabled ?? this.voiceCallEnabled,
      autoCallOnIgnition: autoCallOnIgnition ?? this.autoCallOnIgnition,
      autoCallOnLowTemp: autoCallOnLowTemp ?? this.autoCallOnLowTemp,
      callIncomingNumber: callIncomingNumber ?? this.callIncomingNumber,
      espIp: espIp ?? this.espIp,
      espPort: espPort ?? this.espPort,
      pollIntervalSec: pollIntervalSec ?? this.pollIntervalSec,
      espAutoReconnect: espAutoReconnect ?? this.espAutoReconnect,
      firebaseDbUrl: firebaseDbUrl ?? this.firebaseDbUrl,
      firebaseApiKey: firebaseApiKey ?? this.firebaseApiKey,
      isCloudSyncActive: isCloudSyncActive ?? this.isCloudSyncActive,
      activeTheme: activeTheme ?? this.activeTheme,
    );
  }
}
