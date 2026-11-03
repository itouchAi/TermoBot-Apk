import 'package:flutter/material.dart';

class ObsidianPalette {
  final int id;
  final String name;
  final Color hex;
  final Color borderUnder;
  final Color glow;
  final Color ringColor;
  final Color textColor;
  final List<Color> bgGradient;
  final Color volumetricGlow;
  final Color cardGlow;
  final Color cardBorder;
  final List<Color> pillGradient;

  const ObsidianPalette({
    required this.id,
    required this.name,
    required this.hex,
    required this.borderUnder,
    required this.glow,
    required this.ringColor,
    required this.textColor,
    required this.bgGradient,
    required this.volumetricGlow,
    required this.cardGlow,
    required this.cardBorder,
    required this.pillGradient,
  });
}

const List<ObsidianPalette> obsidianPalettes = [
  // 0. Pastel Lavanta (Varsayılan)
  ObsidianPalette(
    id: 0,
    name: 'Pastel Lavanta',
    hex: Color(0xFF8261E6),
    borderUnder: Color(0xFF3B1C8A),
    glow: Color(0x998261E6),
    ringColor: Color(0xFFA786FF),
    textColor: Color(0xFFD8CAFF),
    bgGradient: [Color(0xFF241444), Color(0xFF110A22), Color(0xFF08050F)],
    volumetricGlow: Color(0x8C8A2BE2),
    cardGlow: Color(0x738261E6),
    cardBorder: Color(0x66A786FF),
    pillGradient: [Color(0xFF7352D4), Color(0xFF8563E8), Color(0xFF9979F5)],
  ),
  // 1. Kül Leylak (Dusty Lilac)
  ObsidianPalette(
    id: 1,
    name: 'Kül Leylak',
    hex: Color(0xFFB388EB),
    borderUnder: Color(0xFF532685),
    glow: Color(0x99AF7FE8),
    ringColor: Color(0xFFD8B4FE),
    textColor: Color(0xFFF3E8FF),
    bgGradient: [Color(0xFF2E1746), Color(0xFF170C26), Color(0xFF0A0512)],
    volumetricGlow: Color(0x8CBA8AF5),
    cardGlow: Color(0x73AF7FE8),
    cardBorder: Color(0x66D8B4FE),
    pillGradient: [Color(0xFF9B6CD8), Color(0xFFAF7FE8), Color(0xFFC79BF2)],
  ),
  // 2. Kraliyet İndigo (Royal Violet)
  ObsidianPalette(
    id: 2,
    name: 'Kraliyet İndigo',
    hex: Color(0xFF5C55DC),
    borderUnder: Color(0xFF27207E),
    glow: Color(0x995C55DC),
    ringColor: Color(0xFF9993FF),
    textColor: Color(0xFFE0E7FF),
    bgGradient: [Color(0xFF181B54), Color(0xFF0B0E2B), Color(0xFF050616)],
    volumetricGlow: Color(0x995C55EB),
    cardGlow: Color(0x735C55DC),
    cardBorder: Color(0x669993FF),
    pillGradient: [Color(0xFF473ECC), Color(0xFF5C55DC), Color(0xFF7871F0)],
  ),
  // 3. Derin Obsidyen Dumanı
  ObsidianPalette(
    id: 3,
    name: 'Derin Obsidyen Dumanı',
    hex: Color(0xFF3F3856),
    borderUnder: Color(0xFF1A1626),
    glow: Color(0x996E5F91),
    ringColor: Color(0xFF8A7EA8),
    textColor: Color(0xFFE6E4F0),
    bgGradient: [Color(0xFF292338), Color(0xFF151121), Color(0xFF0A0810)],
    volumetricGlow: Color(0x7A917EB9),
    cardGlow: Color(0x6B6E5F91),
    cardBorder: Color(0x668A7EA8),
    pillGradient: [Color(0xFF2E293F), Color(0xFF433B5C), Color(0xFF5A507A)],
  ),
];

ObsidianPalette getObsidianPalette(int idx) {
  if (idx >= 0 && idx < obsidianPalettes.length) {
    return obsidianPalettes[idx];
  }
  return obsidianPalettes[3];
}
