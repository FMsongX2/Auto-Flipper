import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/analysis_result.dart';
import '../models/manual_input.dart';
import '../models/app_settings.dart';
import '../models/bookmark.dart';

class PreferencesService {
  static const String _keyAnalysisResult = 'analysis_result';
  static const String _keyManualInput = 'manual_input';
  static const String _keyCurrentPage = 'current_page';
  static const String _keyFilePath = 'file_path';
  static const String _keyAppSettings = 'app_settings';
  static const String _keyBookmarks = 'bookmarks';
  static const String _keyGeminiApiKey = 'gemini_api_key';

  // 분석 결과 저장
  Future<void> saveAnalysisResult(AnalysisResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAnalysisResult, json.encode(result.toJson()));
  }

  // 분석 결과 로드
  Future<AnalysisResult?> loadAnalysisResult() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyAnalysisResult);
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return AnalysisResult.fromJson(json);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // 수동 입력 저장
  Future<void> saveManualInput(ManualInput input) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyManualInput, json.encode(input.toJson()));
  }

  // 수동 입력 로드
  Future<ManualInput?> loadManualInput() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyManualInput);
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return ManualInput.fromJson(json);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // 현재 페이지 저장
  Future<void> saveCurrentPage(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCurrentPage, page);
  }

  // 현재 페이지 로드
  Future<int> loadCurrentPage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCurrentPage) ?? 0;
  }

  // 파일 경로 저장 (다중 이미지 지원)
  Future<void> saveFilePaths(List<String> filePaths) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyFilePath, filePaths);
  }

  // 파일 경로 로드 (다중 이미지 지원)
  Future<List<String>?> loadFilePaths() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyFilePath);
  }

  // 하위 호환성을 위한 단일 파일 경로 저장 (첫 번째 파일만)
  Future<void> saveFilePath(String filePath) async {
    await saveFilePaths([filePath]);
  }

  // 하위 호환성을 위한 단일 파일 경로 로드 (첫 번째 파일만)
  Future<String?> loadFilePath() async {
    final filePaths = await loadFilePaths();
    return filePaths?.isNotEmpty == true ? filePaths![0] : null;
  }

  // 앱 설정 저장
  Future<void> saveAppSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppSettings, json.encode(settings.toJson()));
  }

  // 앱 설정 로드
  Future<AppSettings> loadAppSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyAppSettings);
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return AppSettings.fromJson(json);
      } catch (e) {
        return AppSettings(); // 기본값 반환
      }
    }
    return AppSettings(); // 기본값 반환
  }

  // 북마크 저장
  Future<void> saveBookmarks(List<Bookmark> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = bookmarks.map((b) => b.toJson()).toList();
    await prefs.setString(_keyBookmarks, json.encode(bookmarksJson));
  }

  // 북마크 로드
  Future<List<Bookmark>> loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyBookmarks);
    if (jsonString != null) {
      try {
        final jsonList = jsonDecode(jsonString) as List<dynamic>;
        return jsonList
            .map((json) => Bookmark.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  // Gemini API 키 저장
  Future<void> saveGeminiApiKey(String? apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    if (apiKey != null && apiKey.isNotEmpty) {
      await prefs.setString(_keyGeminiApiKey, apiKey);
    } else {
      await prefs.remove(_keyGeminiApiKey);
    }
  }

  // Gemini API 키 로드
  Future<String?> getGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGeminiApiKey);
  }

  // 모든 데이터 삭제
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAnalysisResult);
    await prefs.remove(_keyManualInput);
    await prefs.remove(_keyCurrentPage);
    await prefs.remove(_keyFilePath);
    await prefs.remove(_keyAppSettings);
    await prefs.remove(_keyBookmarks);
  }
}

