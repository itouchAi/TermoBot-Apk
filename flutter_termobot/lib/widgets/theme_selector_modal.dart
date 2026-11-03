import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/obsidian_palettes.dart';

class ThemeSelectorModal extends StatelessWidget {
  final String currentTheme;
  final ValueChanged<String> onSelectTheme;
  final int selectedPaletteIdx;
  final ValueChanged<int> onSelectPalette;
  final bool isUltraPerformance;
  final ValueChanged<bool> onTogglePerformance;

  const ThemeSelectorModal({
    super.key,
    required this.currentTheme,
    required this.onSelectTheme,
    required this.selectedPaletteIdx,
    required this.onSelectPalette,
    required this.isUltraPerformance,
    required this.onTogglePerformance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF14121E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag indicator
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),

            // Başlık
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.palette_rounded, color: Color(0xFFFF8C32), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Tema & Performans Ayarı',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 16),

            // ── PERFORMANS MODU (60 FPS ULTRA VS ECO) ──
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B29),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isUltraPerformance ? const Color(0xFFFFB800).withOpacity(0.2) : Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isUltraPerformance ? Icons.bolt_rounded : Icons.eco_rounded,
                      color: isUltraPerformance ? const Color(0xFFFFB800) : Colors.green,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUltraPerformance ? '60 FPS Ultra Canavar Modu' : 'Eco Tasarruf Modu',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          isUltraPerformance ? 'GPU auraları ve 3D derinlik aktif' : 'Düşük pil tüketimi ve hafif geçişler',
                          style: const TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isUltraPerformance,
                    activeColor: const Color(0xFFFFB800),
                    onChanged: (val) {
                      HapticFeedback.mediumImpact();
                      onTogglePerformance(val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── ANA TEMALAR LİSTESİ ──
            const Text(
              'GÖRSEL ARAYÜZ TEMASI',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1.0),
            ),
            const SizedBox(height: 8),

            _buildThemeOption(
              id: 'tactile_deck',
              title: '3D Tactile Deck (Koyu Metalik)',
              sub: 'Özel tırtıklı kadran, fiziksel butonlar ve turuncu alev auraları',
              icon: Icons.tune_rounded,
              color: const Color(0xFFFF8C32),
            ),
            _buildThemeOption(
              id: 'obsidian_lavender',
              title: 'Obsidian Lavender (Pastel Mor & Kadife)',
              sub: 'FitVibe stili mat obsidyen cam ve lüks neon auralar',
              icon: Icons.auto_awesome_rounded,
              color: const Color(0xFFA786FF),
            ),
            _buildThemeOption(
              id: 'glass',
              title: 'Canlı Cam (Liquid Glass)',
              sub: 'Saydam buzlu cam ve dinamik atmosferik hava yansıması',
              icon: Icons.layers_rounded,
              color: const Color(0xFF38BDF8),
            ),
            _buildThemeOption(
              id: 'dark',
              title: 'Karanlık Gece Modu',
              sub: 'Derin lacivert & siyah tonları, enerji tasarruflu',
              icon: Icons.dark_mode_rounded,
              color: const Color(0xFF818CF8),
            ),
            _buildThemeOption(
              id: 'light',
              title: 'Aydınlık Gündüz Modu',
              sub: 'Güneş ışığında yüksek okunabilirlik ve gökyüzü mavisi',
              icon: Icons.light_mode_rounded,
              color: const Color(0xFFF59E0B),
            ),

            // ── OBSİDİAN PALET SEÇİCİ (Obsidian seçiliyse) ──
            if (currentTheme == 'obsidian_lavender') ...[
              const SizedBox(height: 14),
              const Text(
                'OBSİDİAN NEON PALETİ',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFA786FF), letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(obsidianPalettes.length, (idx) {
                  final p = obsidianPalettes[idx];
                  final isSel = selectedPaletteIdx == idx;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onSelectPalette(idx);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1B29),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSel ? p.hex : Colors.white12,
                            width: isSel ? 2 : 1,
                          ),
                          boxShadow: isSel
                              ? [
                                  BoxShadow(color: p.glow, blurRadius: 10, spreadRadius: 1),
                                ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: p.hex,
                                boxShadow: [BoxShadow(color: p.hex.withOpacity(0.6), blurRadius: 6)],
                              ),
                              child: isSel ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              p.name.split(' ').first,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: isSel ? Colors.white : Colors.white60,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String id,
    required String title,
    required String sub,
    required IconData icon,
    required Color color,
  }) {
    final isSel = currentTheme == id;
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onSelectTheme(id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF242033) : const Color(0xFF1A1826),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSel ? color : Colors.white12,
            width: isSel ? 1.5 : 1.0,
          ),
          boxShadow: isSel
              ? [
                  BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3)),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isSel ? Colors.white : Colors.white70, fontWeight: FontWeight.bold, fontSize: 12.5)),
                  Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ),
            if (isSel)
              Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
