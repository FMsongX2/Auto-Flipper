class AppSettings {
  final String defaultTimeSignature; // "4/4" | "3/4" | "6/8" | "2/4"
  final bool defaultAutoFlip; // true
  final String animationType; // "fade" | "slide" | "none"
  final int animationDuration; // 100-300 (ms)
  final bool soundFeedback; // true
  final bool vibrationFeedback; // false
  final bool screenRotationLock; // false
  final bool showCountdown; // true - 페이지 넘김 전 카운트다운 표시

  AppSettings({
    this.defaultTimeSignature = '4/4',
    this.defaultAutoFlip = true,
    this.animationType = 'fade',
    this.animationDuration = 200,
    this.soundFeedback = true,
    this.vibrationFeedback = false,
    this.screenRotationLock = false,
    this.showCountdown = true,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      defaultTimeSignature: json['defaultTimeSignature'] as String? ?? '4/4',
      defaultAutoFlip: json['defaultAutoFlip'] as bool? ?? true,
      animationType: json['animationType'] as String? ?? 'fade',
      animationDuration: json['animationDuration'] as int? ?? 200,
      soundFeedback: json['soundFeedback'] as bool? ?? true,
      vibrationFeedback: json['vibrationFeedback'] as bool? ?? false,
      screenRotationLock: json['screenRotationLock'] as bool? ?? false,
      showCountdown: json['showCountdown'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultTimeSignature': defaultTimeSignature,
      'defaultAutoFlip': defaultAutoFlip,
      'animationType': animationType,
      'animationDuration': animationDuration,
      'soundFeedback': soundFeedback,
      'vibrationFeedback': vibrationFeedback,
      'screenRotationLock': screenRotationLock,
      'showCountdown': showCountdown,
    };
  }

  AppSettings copyWith({
    String? defaultTimeSignature,
    bool? defaultAutoFlip,
    String? animationType,
    int? animationDuration,
    bool? soundFeedback,
    bool? vibrationFeedback,
    bool? screenRotationLock,
    bool? showCountdown,
  }) {
    return AppSettings(
      defaultTimeSignature: defaultTimeSignature ?? this.defaultTimeSignature,
      defaultAutoFlip: defaultAutoFlip ?? this.defaultAutoFlip,
      animationType: animationType ?? this.animationType,
      animationDuration: animationDuration ?? this.animationDuration,
      soundFeedback: soundFeedback ?? this.soundFeedback,
      vibrationFeedback: vibrationFeedback ?? this.vibrationFeedback,
      screenRotationLock: screenRotationLock ?? this.screenRotationLock,
      showCountdown: showCountdown ?? this.showCountdown,
    );
  }
}

