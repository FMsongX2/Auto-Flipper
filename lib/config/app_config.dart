/// 앱 설정 및 환경 변수 관리
class AppConfig {
  // BFF 서버 URL
  // 개발 환경: 로컬 서버 또는 에뮬레이터
  // 프로덕션: Vercel 배포 URL
  
  // 디버그 모드 확인
  static bool get isDebugMode {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }
  
  // BFF 서버 기본 URL
  static const String _debugBaseUrl = 'http://10.0.2.2:3000/api'; // Android 에뮬레이터용
  // static const String _releaseBaseUrl = 'https://your-project.vercel.app/api'; // Vercel 배포 URL (배포 시 사용)
  
  /// 현재 환경에 맞는 BFF 서버 URL 반환
  static String get bffBaseUrl {
    // TODO: 실제 배포 URL로 변경
    // if (isDebugMode) {
    //   return _debugBaseUrl;
    // }
    // return _releaseBaseUrl;
    
    // 현재는 디버그 URL 사용
    // 배포 시 아래 주석 해제하고 위의 조건문 사용
    return _debugBaseUrl;
  }
  
  /// 앱 버전
  static const String appVersion = '1.0.0';
  
  /// 최대 파일 크기 (MB)
  static const int maxFileSizeMB = 10;
  
  /// 타임아웃 시간 (초)
  static const int requestTimeoutSeconds = 125;
}

