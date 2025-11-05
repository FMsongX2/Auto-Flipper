import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'ui/screens/splash_screen.dart';
import 'state/score_provider.dart';
import 'state/timer_provider.dart';
import 'services/preferences_service.dart';
import 'services/feedback_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 화면 꺼짐 방지 및 방향 설정
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Provider 생성 및 저장된 데이터 로드
  final provider = ScoreProvider();
  await provider.loadSavedData();
  
  // 앱 설정 로드 및 피드백 서비스 초기화
  final preferencesService = PreferencesService();
  final appSettings = await preferencesService.loadAppSettings();
  FeedbackService.setSoundEnabled(appSettings.soundFeedback);
  FeedbackService.setVibrationEnabled(appSettings.vibrationFeedback);
  
  // API 키는 온디바이스 AI를 사용하므로 더 이상 필요 없음
  // (온디바이스 ML Kit은 API 키가 필요 없음)
  
  // 화면 회전 잠금 설정 적용
  if (appSettings.screenRotationLock) {
    // 현재 방향 고정 (초기화 시에는 세로 모드로)
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }
  
  runApp(MyApp(provider: provider));
}

class MyApp extends StatelessWidget {
  final ScoreProvider provider;
  
  const MyApp({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: provider),
        ChangeNotifierProvider(create: (_) => TimerProvider()),
      ],
      child: MaterialApp(
        title: 'Auto Flipper',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
