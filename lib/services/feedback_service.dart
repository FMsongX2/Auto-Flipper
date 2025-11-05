import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';

class FeedbackService {
  static bool _soundEnabled = true;
  static bool _vibrationEnabled = false;

  // 소리 피드백 설정
  static void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  // 진동 피드백 설정
  static void setVibrationEnabled(bool enabled) {
    _vibrationEnabled = enabled;
  }

  // 페이지 넘김 피드백
  static Future<void> playPageFlipFeedback() async {
    if (_soundEnabled) {
      // 시스템 사운드 재생
      SystemSound.play(SystemSoundType.click);
    }

    if (_vibrationEnabled) {
      // 진동 피드백 (50ms)
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: 50);
      }
    }
  }
}

