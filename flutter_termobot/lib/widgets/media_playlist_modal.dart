import 'package:flutter/material.dart';
import '../models/smart_display_config.dart';

class MediaPlaylistModal extends StatefulWidget {
  final SmartDisplayConfig config;
  final ValueChanged<SmartDisplayConfig> onUpdateConfig;
  final VoidCallback onDismiss;

  const MediaPlaylistModal({
    super.key,
    required this.config,
    required this.onUpdateConfig,
    required this.onDismiss,
  });

  @override
  State<MediaPlaylistModal> createState() => _MediaPlaylistModalState();
}

class _MediaPlaylistModalState extends State<MediaPlaylistModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SmartDisplayConfig _cfg;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cfg = widget.config;
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _addMediaItem(int tabIndex) {
    final title = _titleController.text.trim();
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    final newItem = MediaPlaylistItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: title.isEmpty ? 'Medya Parçası' : title,
      url: url,
    );

    setState(() {
      if (tabIndex == 0) {
        final list = List<MediaPlaylistItem>.from(_cfg.customVideos)..add(newItem);
        _cfg = _cfg.copyWith(customVideos: list, customVideoUrl: url, mode: SmartDisplayMode.video);
      } else if (tabIndex == 1) {
        final list = List<MediaPlaylistItem>.from(_cfg.customImages)..add(newItem);
        _cfg = _cfg.copyWith(customImages: list, customImageUrl: url, mode: SmartDisplayMode.slideshow);
      } else if (tabIndex == 2) {
        final list = List<MediaPlaylistItem>.from(_cfg.customAudioTracks)..add(newItem);
        _cfg = _cfg.copyWith(
          customAudioTracks: list,
          customAudioUrl: url,
          audioTrack: AmbientAudioTrack.custom,
        );
      }
    });

    _titleController.clear();
    _urlController.clear();
    widget.onUpdateConfig(_cfg);
  }

  void _removeItem(int tabIndex, String id) {
    setState(() {
      if (tabIndex == 0) {
        final list = _cfg.customVideos.where((e) => e.id != id).toList();
        _cfg = _cfg.copyWith(customVideos: list);
      } else if (tabIndex == 1) {
        final list = _cfg.customImages.where((e) => e.id != id).toList();
        _cfg = _cfg.copyWith(customImages: list);
      } else if (tabIndex == 2) {
        final list = _cfg.customAudioTracks.where((e) => e.id != id).toList();
        _cfg = _cfg.copyWith(customAudioTracks: list);
      }
    });
    widget.onUpdateConfig(_cfg);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 580,
        constraints: const BoxConstraints(maxHeight: 640),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.75),
              blurRadius: 35,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          children: [
            // Modal Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFF43F5E)],
                      ),
                    ),
                    child: const Icon(Icons.playlist_play_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Display Medya & Akış Yöneticisi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Özel video URL, slayt galerisi ve ambiyans temaları',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onDismiss,
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFF59E0B),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: const Color(0xFFFCD34D),
                unselectedLabelColor: const Color(0xFF94A3B8),
                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(icon: Icon(Icons.videocam_rounded, size: 16), text: 'Videolar'),
                  Tab(icon: Icon(Icons.photo_library_rounded, size: 16), text: 'Görseller'),
                  Tab(icon: Icon(Icons.audiotrack_rounded, size: 16), text: 'Müzikler'),
                  Tab(icon: Icon(Icons.auto_awesome_rounded, size: 16), text: 'Temalar'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Tab View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMediaListTab(0, 'Video Akışı (MP4/HLS)', _cfg.customVideos),
                  _buildMediaListTab(1, 'Görsel URL (JPG/PNG)', _cfg.customImages),
                  _buildMediaListTab(2, 'MP3 Ses Akışı URL', _cfg.customAudioTracks),
                  _buildThemesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaListTab(int tabIndex, String typeLabel, List<MediaPlaylistItem> items) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add URL Form
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yeni $typeLabel Ekle',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE2E8F0),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Başlık veya Açıklama (Örn: Doğa Şöminesi)',
                    hintStyle: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.35)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _urlController,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'https://example.com/media.mp4 veya stream URL...',
                    hintStyle: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.35)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Listeye Ekle', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => _addMediaItem(tabIndex),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Items List
          Text(
            'Kayıtlı Parçalar (${items.length})',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 6),

          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Henüz özel parça eklenmemiş.\nYukarıdan URL ekleyebilir veya Temalar sekmesinden hazır şömine/yağmur seçebilirsiniz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
                ),
              ),
            )
          else
            ...items.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.play_circle_fill_rounded, size: 20, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            item.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFFB7185)),
                      onPressed: () => _removeItem(tabIndex, item.id),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThemesTab() {
    final themes = [
      (PresetVisualTheme.fireplace, 'Şömine Ateşi', 'Canlı parlayan kor ve sıcak kıvılcımlar', Icons.local_fire_department_rounded, const Color(0xFFF97316)),
      (PresetVisualTheme.rainyWindow, 'Yağmurlu Pencere', 'Camda süzülen gerçekçi damlalar', Icons.water_drop_rounded, const Color(0xFF38BDF8)),
      (PresetVisualTheme.winterSnow, 'Kış Karı & Fırtına', 'Sakin ve huzurlu lapa lapa kar yağışı', Icons.ac_unit_rounded, const Color(0xFF93C5FD)),
      (PresetVisualTheme.sunsetForest, 'Gün Batımı Ormanı', 'Sıcak kızıllaşan ufuk ve akşam tonları', Icons.wb_twilight_rounded, const Color(0xFFF43F5E)),
      (PresetVisualTheme.aurora, 'Kutup Işıkları (Aurora)', 'Yeşil ve mor dans eden ipeksi dalgalar', Icons.waves_rounded, const Color(0xFF34D399)),
      (PresetVisualTheme.minimalBlack, 'OLED Saf Siyah', 'Maksimum enerji tasarrufu ve pürüzsüz saat', Icons.dark_mode_rounded, const Color(0xFF64748B)),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hazır Ambiyans Temaları',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.2,
            children: themes.map((t) {
              final isSelected = _cfg.presetTheme == t.$1;
              return InkWell(
                onTap: () {
                  setState(() {
                    _cfg = _cfg.copyWith(
                      presetTheme: t.$1,
                      mode: SmartDisplayMode.aod,
                    );
                  });
                  widget.onUpdateConfig(_cfg);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? t.$5.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? t.$5 : Colors.white.withValues(alpha: 0.12),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: t.$5.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(t.$4, size: 16, color: t.$5),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              t.$2,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                              ),
                            ),
                            Text(
                              t.$3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Equalizer & Visual Settings
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Müzik Ekolayzır Görselleştirici',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Switch(
                      value: _cfg.equalizerEnabled,
                      activeColor: const Color(0xFFF59E0B),
                      onChanged: (val) {
                        setState(() {
                          _cfg = _cfg.copyWith(equalizerEnabled: val);
                        });
                        widget.onUpdateConfig(_cfg);
                      },
                    ),
                  ],
                ),
                if (_cfg.equalizerEnabled) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildEqualizerChip('Neon Sütunlar', EqualizerStyle.bars),
                      const SizedBox(width: 8),
                      _buildEqualizerChip('Sıvı Dalga', EqualizerStyle.wave),
                      const SizedBox(width: 8),
                      _buildEqualizerChip('Bas Halkaları', EqualizerStyle.pulse),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEqualizerChip(String label, EqualizerStyle style) {
    final isSelected = _cfg.equalizerStyle == style;
    return InkWell(
      onTap: () {
        setState(() {
          _cfg = _cfg.copyWith(equalizerStyle: style);
        });
        widget.onUpdateConfig(_cfg);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFFBBF24) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFFFCD34D) : Colors.white70,
          ),
        ),
      ),
    );
  }
}
