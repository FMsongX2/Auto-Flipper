import 'package:flutter/widgets.dart';
import '../state/timer_provider.dart';

class AppLifecycleService extends WidgetsBindingObserver {
  final TimerProvider timerProvider;

  AppLifecycleService(this.timerProvider);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // 백그라운드로 전환 시 타이머 일시정지
        if (timerProvider.state == TimerState.running) {
          timerProvider.pause();
        }
        break;
      case AppLifecycleState.resumed:
        // 포그라운드로 복귀 시 타이머 재개 확인
        // (사용자가 직접 재시작해야 할 수도 있음)
        break;
      case AppLifecycleState.detached:
        // 앱 종료
        timerProvider.stop();
        break;
      case AppLifecycleState.hidden:
        // 앱 숨김
        if (timerProvider.state == TimerState.running) {
          timerProvider.pause();
        }
        break;
    }
  }
}

