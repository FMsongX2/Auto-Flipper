/// API 키 설정 파일 예제
/// 
/// 이 파일을 복사하여 api_keys.dart로 이름을 변경하고
/// API 키를 입력하세요.
/// 
/// 주의: api_keys.dart는 .gitignore에 추가하여
/// Git에 커밋되지 않도록 하세요!
class ApiKeys {
  // Gemini API 키
  // 여기에 API 키를 입력하세요
  static const String geminiApiKey = 'YOUR_API_KEY_HERE';
  
  /// API 키가 설정되어 있는지 확인
  static bool get hasGeminiApiKey => geminiApiKey.isNotEmpty;
  
  /// API 키 가져오기
  static String? getGeminiApiKey() {
    return geminiApiKey;
  }
}

