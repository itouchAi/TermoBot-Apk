import React from 'react';
import { Flame } from 'lucide-react';

interface TactileTelemetryBarProps {
  currentTemp: number;
  humidity: number;
  waterPressure?: number;
  targetTemp: number;
  isKombiActive: boolean;
  flameLevelPercent: number;
  thermalHue?: number;
  sensorBattery?: number;
  isConnected?: boolean;
}

export const TactileTelemetryBar: React.FC<TactileTelemetryBarProps> = ({
  currentTemp,
  humidity,
  waterPressure = 1.6,
  targetTemp,
  isKombiActive,
  flameLevelPercent,
  thermalHue = 300,
  sensorBattery = 92,
  isConnected = true,
}) => {
  return (
    <div
      className="w-full max-w-md mx-auto py-2 px-3.5 sm:px-5 rounded-full flex items-center justify-between font-mono text-[11px] sm:text-xs font-semibold tracking-wider transition-all duration-300 shadow-md select-none shrink-0"
      style={{
        background: 'linear-gradient(172deg, rgba(255, 255, 255, 0.14), transparent 42%), #2a2733',
        boxShadow: '0 4px 0 #0c0b10, 0 8px 14px rgba(0, 0, 0, 0.55)',
        border: '1px solid rgba(255, 255, 255, 0.14)',
        color: `hsl(${thermalHue} 90% 74%)`,
        textShadow: `0 0 10px hsl(${thermalHue} 90% 65% / 0.55)`,
      }}
    >
      {/* 1. Canlı Oda Sıcaklığı */}
      <div className="flex items-center gap-1.5 shrink-0">
        <span className="opacity-80">ODA:</span>
        <span className="font-mono font-black text-white text-xs sm:text-sm drop-shadow-sm">
          {currentTemp.toFixed(1)}°C
        </span>
      </div>

      {/* Dikey Ayırıcı */}
      <span className="opacity-30">|</span>

      {/* 2. Su Basıncı */}
      <div className="flex items-center gap-1.5 shrink-0">
        <span className="opacity-80">BASINÇ:</span>
        <span className="font-mono font-black text-white text-xs sm:text-sm drop-shadow-sm">
          {waterPressure.toFixed(1)} Bar
        </span>
      </div>

      {/* Dikey Ayırıcı */}
      <span className="opacity-30">|</span>

      {/* 3. Hedef Sıcaklık & Yanma Durumu */}
      <div className="flex items-center gap-1.5 shrink-0">
        <span className="opacity-80">HEDEF:</span>
        <span className="font-mono font-black text-white text-xs sm:text-sm drop-shadow-sm flex items-center gap-1">
          {targetTemp.toFixed(1)}°
          {isKombiActive && (
            <Flame className="w-3.5 h-3.5 text-orange-400 fill-orange-400 animate-pulse inline-block -mt-0.5" />
          )}
        </span>
      </div>

      {/* Dikey Ayırıcı */}
      <span className="opacity-30">|</span>

      {/* 4. Bağlantı & Pil Durumu */}
      <div className="flex items-center gap-1.5 shrink-0">
        {!isConnected ? (
          <span className="px-1.5 py-0.5 rounded-full bg-red-500/25 border border-red-500/50 text-red-300 font-bold text-[10px] animate-pulse">
            ⚠️ KOPUK
          </span>
        ) : sensorBattery < 20 ? (
          <span className="px-1.5 py-0.5 rounded-full bg-amber-500/25 border border-amber-500/50 text-amber-300 font-bold text-[10px] animate-pulse">
            🪫 %{sensorBattery}
          </span>
        ) : (
          <span className="text-[10px] text-emerald-400 font-bold flex items-center gap-1" title={`Sensör Pili: %${sensorBattery} • ESP32 Çevrimiçi`}>
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
            <span>%{sensorBattery}</span>
          </span>
        )}
      </div>
    </div>
  );
};
