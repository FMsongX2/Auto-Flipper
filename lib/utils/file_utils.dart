import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class FileUtils {
  /// 파일 확장자 확인
  static bool isPdf(String filePath) {
    return filePath.toLowerCase().endsWith('.pdf');
  }

  /// 이미지 파일 확인
  static bool isImage(String filePath) {
    final lowerPath = filePath.toLowerCase();
    return lowerPath.endsWith('.jpg') ||
        lowerPath.endsWith('.jpeg') ||
        lowerPath.endsWith('.png');
  }

  /// 지원되는 파일 형식 확인
  static bool isSupportedFile(String filePath) {
    return isPdf(filePath) || isImage(filePath);
  }

  /// 파일명 추출
  static String getFileName(String filePath) {
    return filePath.split('/').last.split('\\').last;
  }

  /// 파일 존재 확인
  static Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// 파일을 앱의 영구 저장소로 복사
  /// 앱 재시작 후에도 접근 가능하도록 보장
  static Future<String> copyToPermanentStorage(String sourcePath, String fileName) async {
    try {
      // 앱의 문서 디렉토리 가져오기 (영구 저장소)
      final appDir = await getApplicationDocumentsDirectory();
      final scoresDir = Directory(path.join(appDir.path, 'scores'));
      
      // 디렉토리가 없으면 생성
      if (!await scoresDir.exists()) {
        await scoresDir.create(recursive: true);
      }
      
      // 목적지 파일 경로 생성
      final destinationPath = path.join(scoresDir.path, fileName);
      final destinationFile = File(destinationPath);
      
      // 이미 존재하는 파일이면 덮어쓰기
      if (await destinationFile.exists()) {
        await destinationFile.delete();
      }
      
      // 파일 복사
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(destinationPath);
        return destinationPath;
      } else {
        throw Exception('소스 파일을 찾을 수 없습니다: $sourcePath');
      }
    } catch (e) {
      // 복사 실패 시 원본 경로 반환 (fallback)
      return sourcePath;
    }
  }

  /// 여러 파일을 앱의 영구 저장소로 복사
  static Future<List<String>> copyFilesToPermanentStorage(List<String> sourcePaths) async {
    final copiedPaths = <String>[];
    
    for (final sourcePath in sourcePaths) {
      final fileName = getFileName(sourcePath);
      // 파일명 중복 방지를 위해 타임스탬프 추가
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '$timestamp-$fileName';
      
      final copiedPath = await copyToPermanentStorage(sourcePath, uniqueFileName);
      copiedPaths.add(copiedPath);
    }
    
    return copiedPaths;
  }
}

