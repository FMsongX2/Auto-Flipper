import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'permission_service.dart';

class FilePickerService {
  /// PDF 또는 단일 이미지 선택 (하위 호환성)
  Future<String?> pickPdfOrImage() async {
    final result = await pickPdfOrImages();
    if (result != null && result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  /// PDF 또는 다중 이미지 선택
  /// Returns: 파일 경로 리스트 (PDF인 경우 1개, 이미지인 경우 여러 개)
  Future<List<String>?> pickPdfOrImages() async {
    // 🔥 CRITICAL: 파일 선택 전 권한 확인 및 요청 (갤럭시 탭 등 실제 기기에서 필수)
    final hasPermission = await PermissionService.checkStoragePermission();
    if (!hasPermission) {
      debugPrint('FilePickerService: pickPdfOrImages - Storage permission not granted, requesting...');
      // FilePickerService는 BuildContext가 없으므로, 권한 요청은 호출하는 쪽에서 처리
      // 여기서는 권한이 없으면 null 반환
      debugPrint('FilePickerService: pickPdfOrImages - Storage permission denied, cannot pick files');
      return null;
    }
    debugPrint('FilePickerService: pickPdfOrImages - Storage permission granted');
    
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: true, // 다중 선택 허용
    );
    
    if (result != null && result.files.isNotEmpty) {
      final files = result.files;
      final paths = <String>[];
      
      for (final file in files) {
        // Android에서는 path가 null일 수 있으므로 name과 bytes를 사용
        final path = file.path ?? (file.name.isNotEmpty ? file.name : null);
        if (path != null) {
          paths.add(path);
        }
      }
      
      if (paths.isNotEmpty) {
        // PDF가 포함되어 있으면 PDF만 반환 (PDF와 이미지 혼합 방지)
        final pdfPaths = paths.where((p) => p.toLowerCase().endsWith('.pdf')).toList();
        if (pdfPaths.isNotEmpty) {
          // PDF는 단일 파일만 지원
          return [pdfPaths.first];
        }
        // 이미지만 있는 경우 모든 이미지 반환
        return paths;
      }
    }
    return null;
  }

  /// 이미지 파일만 선택 (미리보기 이미지용)
  Future<String?> pickImageFile() async {
    // 🔥 CRITICAL: 파일 선택 전 권한 확인 및 요청 (갤럭시 탭 등 실제 기기에서 필수)
    final hasPermission = await PermissionService.checkStoragePermission();
    if (!hasPermission) {
      debugPrint('FilePickerService: pickImageFile - Storage permission not granted, requesting...');
      // FilePickerService는 BuildContext가 없으므로, 권한 요청은 호출하는 쪽에서 처리
      // 여기서는 권한이 없으면 null 반환
      debugPrint('FilePickerService: pickImageFile - Storage permission denied, cannot pick files');
      return null;
    }
    debugPrint('FilePickerService: pickImageFile - Storage permission granted');
    
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      // Android에서는 path가 null일 수 있으므로 name과 bytes를 사용
      final path = file.path ?? (file.name.isNotEmpty ? file.name : null);
      return path;
    }
    return null;
  }
}

