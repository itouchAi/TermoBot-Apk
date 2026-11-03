import 'dart:convert';

enum SmartDisplayMode {
  aod,
  video,
  videoAudioMutedMp3,
  image,
  slideshow,
}

enum AmbientAudioTrack {
  none,
  fireplace,
  rain,
  lofi,
  relaxPiano,
  nature,
  custom,
}

enum SlideTransition {
  fade,
  slide,
  zoom,
}

enum ImageFitMode {
  cover,
  contain,
  fill,
}

enum EqualizerStyle {
  bars,
  wave,
  pulse,
}

enum PresetVisualTheme {
  fireplace,
  rainyWindow,
  winterSnow,
  sunsetForest,
  aurora,
  minimalBlack,
  custom,
}

class MediaPlaylistItem {
  final String id;
  final String name;
  final String url;

  const MediaPlaylistItem({
    required this.id,
    required this.name,
    required this.url,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
      };

  factory MediaPlaylistItem.fromJson(Map<String, dynamic> json) =>
      MediaPlaylistItem(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Medya Parçası',
        url: json['url'] as String? ?? '',
      );
}

class SmartDisplayConfig {
  final bool enabled;
  final SmartDisplayMode mode;
  final PresetVisualTheme presetTheme;
  final String customImageUrl;
  final String customVideoUrl;
  final List<MediaPlaylistItem> customImages;
  final List<MediaPlaylistItem> customVideos;
  final List<MediaPlaylistItem> customAudioTracks;
  final ImageFitMode imageFitMode;
  final int slideshowIntervalSec;
  final SlideTransition slideTransition;
  final AmbientAudioTrack audioTrack;
  final String customAudioUrl;
  final double audioVolume;
  final int brightnessPercent;
  final int sleepTimeoutMin;
  final bool burnInProtection;
  final bool showMarqueeTrackTitle;
  final bool equalizerEnabled;
  final EqualizerStyle equalizerStyle;
  final bool isLoop;

  const SmartDisplayConfig({
    this.enabled = true,
    this.mode = SmartDisplayMode.aod,
    this.presetTheme = PresetVisualTheme.fireplace,
    this.customImageUrl = '',
    this.customVideoUrl = '',
    this.customImages = const [],
    this.customVideos = const [],
    this.customAudioTracks = const [],
    this.imageFitMode = ImageFitMode.cover,
    this.slideshowIntervalSec = 10,
    this.slideTransition = SlideTransition.fade,
    this.audioTrack = AmbientAudioTrack.none,
    this.customAudioUrl = '',
    this.audioVolume = 0.5,
    this.brightnessPercent = 85,
    this.sleepTimeoutMin = 0,
    this.burnInProtection = true,
    this.showMarqueeTrackTitle = true,
    this.equalizerEnabled = false,
    this.equalizerStyle = EqualizerStyle.bars,
    this.isLoop = true,
  });

  SmartDisplayConfig copyWith({
    bool? enabled,
    SmartDisplayMode? mode,
    PresetVisualTheme? presetTheme,
    String? customImageUrl,
    String? customVideoUrl,
    List<MediaPlaylistItem>? customImages,
    List<MediaPlaylistItem>? customVideos,
    List<MediaPlaylistItem>? customAudioTracks,
    ImageFitMode? imageFitMode,
    int? slideshowIntervalSec,
    SlideTransition? slideTransition,
    AmbientAudioTrack? audioTrack,
    String? customAudioUrl,
    double? audioVolume,
    int? brightnessPercent,
    int? sleepTimeoutMin,
    bool? burnInProtection,
    bool? showMarqueeTrackTitle,
    bool? equalizerEnabled,
    EqualizerStyle? equalizerStyle,
    bool? isLoop,
  }) {
    return SmartDisplayConfig(
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      presetTheme: presetTheme ?? this.presetTheme,
      customImageUrl: customImageUrl ?? this.customImageUrl,
      customVideoUrl: customVideoUrl ?? this.customVideoUrl,
      customImages: customImages ?? this.customImages,
      customVideos: customVideos ?? this.customVideos,
      customAudioTracks: customAudioTracks ?? this.customAudioTracks,
      imageFitMode: imageFitMode ?? this.imageFitMode,
      slideshowIntervalSec: slideshowIntervalSec ?? this.slideshowIntervalSec,
      slideTransition: slideTransition ?? this.slideTransition,
      audioTrack: audioTrack ?? this.audioTrack,
      customAudioUrl: customAudioUrl ?? this.customAudioUrl,
      audioVolume: audioVolume ?? this.audioVolume,
      brightnessPercent: brightnessPercent ?? this.brightnessPercent,
      sleepTimeoutMin: sleepTimeoutMin ?? this.sleepTimeoutMin,
      burnInProtection: burnInProtection ?? this.burnInProtection,
      showMarqueeTrackTitle: showMarqueeTrackTitle ?? this.showMarqueeTrackTitle,
      equalizerEnabled: equalizerEnabled ?? this.equalizerEnabled,
      equalizerStyle: equalizerStyle ?? this.equalizerStyle,
      isLoop: isLoop ?? this.isLoop,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'mode': mode.name,
        'presetTheme': presetTheme.name,
        'customImageUrl': customImageUrl,
        'customVideoUrl': customVideoUrl,
        'customImages': customImages.map((e) => e.toJson()).toList(),
        'customVideos': customVideos.map((e) => e.toJson()).toList(),
        'customAudioTracks': customAudioTracks.map((e) => e.toJson()).toList(),
        'imageFitMode': imageFitMode.name,
        'slideshowIntervalSec': slideshowIntervalSec,
        'slideTransition': slideTransition.name,
        'audioTrack': audioTrack.name,
        'customAudioUrl': customAudioUrl,
        'audioVolume': audioVolume,
        'brightnessPercent': brightnessPercent,
        'sleepTimeoutMin': sleepTimeoutMin,
        'burnInProtection': burnInProtection,
        'showMarqueeTrackTitle': showMarqueeTrackTitle,
        'equalizerEnabled': equalizerEnabled,
        'equalizerStyle': equalizerStyle.name,
        'isLoop': isLoop,
      };

  factory SmartDisplayConfig.fromJson(Map<String, dynamic> json) {
    return SmartDisplayConfig(
      enabled: json['enabled'] as bool? ?? true,
      mode: SmartDisplayMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => SmartDisplayMode.aod,
      ),
      presetTheme: PresetVisualTheme.values.firstWhere(
        (e) => e.name == json['presetTheme'],
        orElse: () => PresetVisualTheme.fireplace,
      ),
      customImageUrl: json['customImageUrl'] as String? ?? '',
      customVideoUrl: json['customVideoUrl'] as String? ?? '',
      customImages: (json['customImages'] as List<dynamic>?)
              ?.map((e) => MediaPlaylistItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      customVideos: (json['customVideos'] as List<dynamic>?)
              ?.map((e) => MediaPlaylistItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      customAudioTracks: (json['customAudioTracks'] as List<dynamic>?)
              ?.map((e) => MediaPlaylistItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      imageFitMode: ImageFitMode.values.firstWhere(
        (e) => e.name == json['imageFitMode'],
        orElse: () => ImageFitMode.cover,
      ),
      slideshowIntervalSec: json['slideshowIntervalSec'] as int? ?? 10,
      slideTransition: SlideTransition.values.firstWhere(
        (e) => e.name == json['slideTransition'],
        orElse: () => SlideTransition.fade,
      ),
      audioTrack: AmbientAudioTrack.values.firstWhere(
        (e) => e.name == json['audioTrack'],
        orElse: () => AmbientAudioTrack.none,
      ),
      customAudioUrl: json['customAudioUrl'] as String? ?? '',
      audioVolume: (json['audioVolume'] as num?)?.toDouble() ?? 0.5,
      brightnessPercent: json['brightnessPercent'] as int? ?? 85,
      sleepTimeoutMin: json['sleepTimeoutMin'] as int? ?? 0,
      burnInProtection: json['burnInProtection'] as bool? ?? true,
      showMarqueeTrackTitle: json['showMarqueeTrackTitle'] as bool? ?? true,
      equalizerEnabled: json['equalizerEnabled'] as bool? ?? false,
      equalizerStyle: EqualizerStyle.values.firstWhere(
        (e) => e.name == json['equalizerStyle'],
        orElse: () => EqualizerStyle.bars,
      ),
      isLoop: json['isLoop'] as bool? ?? true,
    );
  }
}
