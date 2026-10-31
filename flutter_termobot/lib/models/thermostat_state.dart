class ThermostatState {
  double currentTemp;
  double targetTemp;
  double humidity;
  double waterPressure;
  int flameModulation; // 0 - 100%
  bool isRelayActive;
  bool isConnected;
  String currentMode; // 'eco' | 'comfort' | 'boost' | 'manual'
  String espIp;

  ThermostatState({
    this.currentTemp = 21.8,
    this.targetTemp = 22.5,
    this.humidity = 48.0,
    this.waterPressure = 1.5,
    this.flameModulation = 68,
    this.isRelayActive = true,
    this.isConnected = true,
    this.currentMode = 'comfort',
    this.espIp = '192.168.1.150',
  });

  ThermostatState copyWith({
    double? currentTemp,
    double? targetTemp,
    double? humidity,
    double? waterPressure,
    int? flameModulation,
    bool? isRelayActive,
    bool? isConnected,
    String? currentMode,
    String? espIp,
  }) {
    return ThermostatState(
      currentTemp: currentTemp ?? this.currentTemp,
      targetTemp: targetTemp ?? this.targetTemp,
      humidity: humidity ?? this.humidity,
      waterPressure: waterPressure ?? this.waterPressure,
      flameModulation: flameModulation ?? this.flameModulation,
      isRelayActive: isRelayActive ?? this.isRelayActive,
      isConnected: isConnected ?? this.isConnected,
      currentMode: currentMode ?? this.currentMode,
      espIp: espIp ?? this.espIp,
    );
  }
}
