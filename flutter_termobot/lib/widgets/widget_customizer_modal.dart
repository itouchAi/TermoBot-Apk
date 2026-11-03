import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WidgetCustomizerModal extends StatefulWidget {
  final List<String> tabOrder;
  final ValueChanged<List<String>> onUpdateTabOrder;

  const WidgetCustomizerModal({
    super.key,
    required this.tabOrder,
    required this.onUpdateTabOrder,
  });

  @override
  State<WidgetCustomizerModal> createState() => _WidgetCustomizerModalState();
}

class _WidgetCustomizerModalState extends State<WidgetCustomizerModal> {
  late List<String> _tabs;

  final Map<String, Map<String, String>> _tabDefs = {
    'genel': {'title': 'Termo.', 'subtitle': 'Termostat & Kombi Ana Kontrol', 'icon': '🏠'},
    'hava': {'title': 'Hava', 'subtitle': 'Bölgesel Hava Durumu & 5 Günlük Tahmin', 'icon': '🌤️'},
    'rapor': {'title': 'Rapor', 'subtitle': '24s Sıcaklık & Tüketim Analitiği', 'icon': '📊'},
    'program': {'title': 'Prog.', 'subtitle': 'Haftalık Zaman Planı & Tüketim', 'icon': '⏰'},
  };

  @override
  void initState() {
    super.initState();
    _tabs = List.from(widget.tabOrder);
  }

  void _move(int index, int delta) {
    final newIdx = index + delta;
    if (newIdx < 0 || newIdx >= _tabs.length) return;
    HapticFeedback.selectionClick();
    setState(() {
      final item = _tabs.removeAt(index);
      _tabs.insert(newIdx, item);
    });
    widget.onUpdateTabOrder(_tabs);
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    final defaultTabs = ['genel', 'hava', 'rapor', 'program'];
    setState(() => _tabs = List.from(defaultTabs));
    widget.onUpdateTabOrder(defaultTabs);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161422),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.tune_rounded, color: Color(0xFFFF8C32), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Ekran & Menü Sıralaması',
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
          const Text(
            'Ekranlarınızı yukarı/aşağı butonlarıyla dilediğiniz gibi sıralayın.',
            style: TextStyle(fontSize: 11, color: Colors.white60),
          ),
          const SizedBox(height: 14),
          ...List.generate(_tabs.length, (i) {
            final id = _tabs[i];
            final def = _tabDefs[id] ?? {'title': id, 'subtitle': '', 'icon': '📄'};
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF221F2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Text(def['icon']!, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(def['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(def['subtitle']!, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                        color: i > 0 ? Colors.white70 : Colors.white24,
                        onPressed: i > 0 ? () => _move(i, -1) : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                        color: i < _tabs.length - 1 ? Colors.white70 : Colors.white24,
                        onPressed: i < _tabs.length - 1 ? () => _move(i, 1) : null,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white60),
                  label: const Text('Varsayılana Sıfırla', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  onPressed: _reset,
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C32)),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tamam', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
