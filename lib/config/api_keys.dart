/// API 키 설정 파일
/// 
/// 이 파일에 API 키를 직접 입력하거나,
/// 환경 변수에서 읽어올 수 있습니다.
/// 
/// 주의: 이 파일을 Git에 커밋하지 마세요!
/// .gitignore에 추가하는 것을 권장합니다.
class ApiKeys {
  // Gemini API 키
  // 방법 1: 직접 입력 (개발용)
  static const String geminiApiKey = 'AIzaSyB-ex2g7LP32h95nuwQkSkLehrAbL9-FmU'; // 여기에 API 키 입력
  
  // 방법 2: 환경 변수에서 읽기 (권장)
  // 환경 변수에서 읽으려면 아래 주석을 해제하고 위의 직접 입력을 null로 설정
  // static const String? geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  
  // 방법 3: 앱 내 설정 화면에서 입력 (현재 방식)
  // 설정 화면에서 입력한 키는 SharedPreferences에 저장되며,
  // 이 파일의 값보다 우선적으로 사용됩니다.
  
  /// API 키가 설정되어 있는지 확인
  static bool get hasGeminiApiKey => geminiApiKey.isNotEmpty;
  
  /// API 키 가져오기
  /// 
  /// 우선순위:
  /// 1. SharedPreferences에 저장된 키 (사용자가 설정 화면에서 입력)
  /// 2. 이 파일에 직접 입력된 키
  /// 3. 환경 변수에서 읽은 키
  static String? getGeminiApiKey() {
    // 현재는 SharedPreferences에서만 읽음
    // 필요시 이 파일의 값도 고려할 수 있음
    return geminiApiKey;
  }
}

