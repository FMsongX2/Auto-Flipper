import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

/// 권한 요청 서비스
/// 갤럭시 탭 등 실제 기기에서 파일 접근 권한을 요청하고 관리합니다.
class PermissionService {
  /// 저장소 읽기 권한 요청
  /// Android 12 이하: READ_EXTERNAL_STORAGE
  /// Android 13 이상: READ_MEDIA_IMAGES, READ_MEDIA_VIDEO
  static Future<bool> requestStoragePermission(BuildContext? context) async {
    if (kIsWeb) {
      // 웹에서는 권한이 필요 없음
      return true;
    }

    if (!Platform.isAndroid) {
      // Android가 아니면 권한이 필요 없음
      return true;
    }

    try {
      // Android 13 (API 33) 이상인 경우 READ_MEDIA_IMAGES 사용
      // Android 12 이하는 READ_EXTERNAL_STORAGE 사용
      // permission_handler가 자동으로 처리하지만, 명시적으로 처리
      
      // 먼저 Android 13 이상 권한 시도
      Permission permissionToRequest;
      
      try {
        // Android 13 이상에서는 photos 권한이 사용 가능
        final photosStatus = await Permission.photos.status;
        if (photosStatus != PermissionStatus.denied && photosStatus != PermissionStatus.restricted) {
          // Android 13 이상
          permissionToRequest = Permission.photos;
          debugPrint('PermissionService: Using photos permission (Android 13+)');
        } else {
          // Android 12 이하로 fallback
          permissionToRequest = Permission.storage;
          debugPrint('PermissionService: Using storage permission (Android 12 or below)');
        }
      } catch (e) {
        // photos 권한이 지원되지 않는 경우 (Android 12 이하)
        permissionToRequest = Permission.storage;
        debugPrint('PermissionService: photos permission not available, using storage permission');
      }
      
      final status = await permissionToRequest.status;
      if (status.isGranted) {
        debugPrint('PermissionService: Storage permission already granted');
        return true;
      }
      
      if (status.isPermanentlyDenied) {
        debugPrint('PermissionService: Storage permission permanently denied');
        if (context != null && context.mounted) {
          _showPermissionDeniedDialog(context);
        }
        return false;
      }
      
      debugPrint('PermissionService: Requesting storage permission...');
      final result = await permissionToRequest.request();
      
      if (result.isGranted) {
        debugPrint('PermissionService: Storage permission granted');
        return true;
      } else if (result.isPermanentlyDenied) {
        debugPrint('PermissionService: Storage permission permanently denied');
        if (context != null && context.mounted) {
          _showPermissionDeniedDialog(context);
        }
        return false;
      } else {
        debugPrint('PermissionService: Storage permission denied');
        return false;
      }
    } catch (e) {
      debugPrint('PermissionService: Error requesting storage permission: $e');
      // 에러 발생 시 기본적으로 storage 권한 시도
      try {
        final result = await Permission.storage.request();
        return result.isGranted;
      } catch (e2) {
        debugPrint('PermissionService: Fallback storage permission also failed: $e2');
        return false;
      }
    }
  }

  /// 권한이 거부되었을 때 설정 화면으로 이동하는 다이얼로그 표시
  static void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('저장소 권한 필요'),
        content: const Text(
          '악보 파일을 불러오려면 저장소 접근 권한이 필요합니다.\n\n'
          '설정 화면에서 권한을 허용해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('설정 열기'),
          ),
        ],
      ),
    );
  }

  /// 현재 저장소 권한 상태 확인
  static Future<bool> checkStoragePermission() async {
    if (kIsWeb) {
      return true;
    }

    if (!Platform.isAndroid) {
      return true;
    }

    try {
      // Android 13 이상 권한 확인 시도
      try {
        final photosStatus = await Permission.photos.status;
        if (photosStatus.isGranted) {
          debugPrint('PermissionService: Photos permission granted (Android 13+)');
          return true;
        }
        // Android 13 이상이지만 권한이 없는 경우
      } catch (e) {
        // photos 권한이 지원되지 않는 경우 (Android 12 이하)
        debugPrint('PermissionService: photos permission not available, checking storage permission');
      }
      
      // Android 12 이하 권한 확인
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) {
        debugPrint('PermissionService: Storage permission granted (Android 12 or below)');
        return true;
      }
      
      debugPrint('PermissionService: No storage permission granted');
      return false;
    } catch (e) {
      debugPrint('PermissionService: Error checking storage permission: $e');
      return false;
    }
  }
}

