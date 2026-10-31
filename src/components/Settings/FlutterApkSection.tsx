import React, { useState } from 'react';
import { Smartphone, Zap, Download, CheckCircle2, Copy, Sparkles, Terminal } from 'lucide-react';

export const FlutterApkSection: React.FC = () => {
  const [copied, setCopied] = useState<string | null>(null);

  const handleCopy = (text: string, key: string) => {
    navigator.clipboard.writeText(text);
    setCopied(key);
    setTimeout(() => setCopied(null), 2000);
  };

  return (
    <div className="space-y-4">
      {/* Hero Badge */}
      <div className="p-4 rounded-2xl bg-gradient-to-br from-amber-500/15 via-orange-500/10 to-transparent border border-amber-500/30">
        <div className="flex items-center gap-3 mb-2">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-amber-500 to-orange-600 flex items-center justify-center text-white shadow-lg shadow-orange-500/30">
            <Zap className="w-5 h-5" />
          </div>
          <div>
            <h4 className="text-sm font-bold text-white flex items-center gap-2">
              Saf Flutter & GPU Çizim Motoru
              <span className="text-[10px] px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 font-semibold">
                120 FPS • WebView YOK
              </span>
            </h4>
            <p className="text-xs text-slate-400">
              Chrome/Tarayıcı motoru olmadan doğrudan telefonun grafik işlemcisine (GPU) çizen saf mobil mimari.
            </p>
          </div>
        </div>
      </div>

      {/* GitHub Actions 1-Click Cloud APK Build */}
      <div className="p-4 rounded-2xl bg-slate-900/60 border border-slate-800">
        <h5 className="text-xs font-bold text-amber-400 uppercase tracking-wider mb-2 flex items-center gap-2">
          <Download className="w-4 h-4" />
          1. GitHub Actions ile Tek Tıkla APK İndirme (Bulut Derleme)
        </h5>
        <p className="text-xs text-slate-300 leading-relaxed mb-3">
          Bilgisayarınıza hiçbir şey kurmadan, doğrudan GitHub sunucuları üzerinden saf Flutter APK dosyanızı oluşturabilirsiniz:
        </p>
        <ol className="text-xs text-slate-400 space-y-2 list-decimal list-inside bg-slate-950/70 p-3 rounded-xl border border-slate-800/80">
          <li>Reponuzu GitHub'a push edin veya GitHub deponuzu açın.</li>
          <li>Üst menüden <strong className="text-slate-200">Actions</strong> sekmesine tıklayın.</li>
          <li>Sol taraftan <strong className="text-amber-400">"Build Pure Flutter APK"</strong> iş akışını seçin.</li>
          <li><strong className="text-slate-200">"Run workflow"</strong> butonuna basın.</li>
          <li>2-3 dakika sonra <strong className="text-emerald-400">Artifacts</strong> altından <code className="text-orange-300">TermoBot-Pure-Flutter-Release-APK</code> dosyasını indirip telefonunuza kurun!</li>
        </ol>
      </div>

      {/* Local Flutter Terminal Commands */}
      <div className="p-4 rounded-2xl bg-slate-900/60 border border-slate-800">
        <h5 className="text-xs font-bold text-cyan-400 uppercase tracking-wider mb-2 flex items-center gap-2">
          <Terminal className="w-4 h-4" />
          2. Kendi Bilgisayarınızda Çalıştırma / Derleme
        </h5>
        <p className="text-xs text-slate-400 mb-2">
          Projeyi bilgisayarınıza indirdiğinizde <code className="text-slate-200">/flutter_termobot</code> klasöründe terminali açıp şu komutları çalıştırabilirsiniz:
        </p>

        <div className="space-y-2">
          <div className="flex items-center justify-between bg-black/60 px-3 py-2 rounded-lg font-mono text-xs text-slate-300 border border-white/5">
            <span>cd flutter_termobot && flutter pub get</span>
            <button
              onClick={() => handleCopy('cd flutter_termobot && flutter pub get', 'cmd1')}
              className="text-slate-400 hover:text-white p-1"
            >
              {copied === 'cmd1' ? <CheckCircle2 className="w-4 h-4 text-emerald-400" /> : <Copy className="w-4 h-4" />}
            </button>
          </div>

          <div className="flex items-center justify-between bg-black/60 px-3 py-2 rounded-lg font-mono text-xs text-slate-300 border border-white/5">
            <span>flutter build apk --release</span>
            <button
              onClick={() => handleCopy('flutter build apk --release', 'cmd2')}
              className="text-slate-400 hover:text-white p-1"
            >
              {copied === 'cmd2' ? <CheckCircle2 className="w-4 h-4 text-emerald-400" /> : <Copy className="w-4 h-4" />}
            </button>
          </div>

          <div className="flex items-center justify-between bg-black/60 px-3 py-2 rounded-lg font-mono text-xs text-slate-300 border border-white/5">
            <span>flutter build ios --no-codesign</span>
            <button
              onClick={() => handleCopy('flutter build ios --no-codesign', 'cmd3')}
              className="text-slate-400 hover:text-white p-1"
            >
              {copied === 'cmd3' ? <CheckCircle2 className="w-4 h-4 text-emerald-400" /> : <Copy className="w-4 h-4" />}
            </button>
          </div>
        </div>
      </div>

      {/* Architecture Highlights */}
      <div className="grid grid-cols-2 gap-2 text-xs">
        <div className="p-3 rounded-xl bg-slate-900/40 border border-slate-800/60">
          <div className="font-semibold text-slate-200 mb-1">🎮 Impeller / Skia GPU</div>
          <div className="text-[11px] text-slate-400">CustomPainter ile kadranda sıfır gecikmeli, 120 Hz pürüzsüz dokunma tepkisi.</div>
        </div>
        <div className="p-3 rounded-xl bg-slate-900/40 border border-slate-800/60">
          <div className="font-semibold text-slate-200 mb-1">⚡ Bağımsız Çalışma</div>
          <div className="text-[11px] text-slate-400">ESP32 yerel ağına doğrudan HTTP REST istekleri gönderir, internet kesilse de çalışır.</div>
        </div>
      </div>
    </div>
  );
};
