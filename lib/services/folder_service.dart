import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/folder.dart';
import '../models/score_item.dart';
import 'dart:io';

class FolderService {
  static const String _keyFolders = 'folders';
  static const _uuid = Uuid();

  // 모든 폴더 로드
  Future<List<Folder>> loadFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyFolders);
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString) as List<dynamic>;
        return json
            .map((e) => Folder.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  // 폴더 저장
  Future<void> saveFolders(List<Folder> folders) async {
    final prefs = await SharedPreferences.getInstance();
    final json = folders.map((f) => f.toJson()).toList();
    await prefs.setString(_keyFolders, jsonEncode(json));
  }

  // 폴더 추가
  Future<Folder> addFolder({
    required String name,
    String color = '#2196F3',
  }) async {
    final folders = await loadFolders();
    final now = DateTime.now();
    final folder = Folder(
      id: _uuid.v4(),
      name: name,
      color: color,
      createdAt: now,
      updatedAt: now,
    );
    folders.add(folder);
    await saveFolders(folders);
    return folder;
  }

  // 폴더 업데이트
  Future<void> updateFolder(Folder folder) async {
    final folders = await loadFolders();
    final index = folders.indexWhere((f) => f.id == folder.id);
    if (index >= 0) {
      folders[index] = folder.copyWith(updatedAt: DateTime.now());
      await saveFolders(folders);
    }
  }

  // 폴더 삭제
  Future<void> deleteFolder(String folderId) async {
    final folders = await loadFolders();
    folders.removeWhere((f) => f.id == folderId);
    await saveFolders(folders);
  }

  // 폴더에 악보 추가
  Future<void> addScoreToFolder(String folderId, ScoreItem score) async {
    final folders = await loadFolders();
    final folderIndex = folders.indexWhere((f) => f.id == folderId);
    if (folderIndex >= 0) {
      final updatedScores = List<ScoreItem>.from(folders[folderIndex].scores);
      updatedScores.add(score);
      folders[folderIndex] = folders[folderIndex].copyWith(
        scores: updatedScores,
        updatedAt: DateTime.now(),
      );
      await saveFolders(folders);
    }
  }

  // 폴더에서 악보 업데이트
  Future<void> updateScoreInFolder(String folderId, ScoreItem score) async {
    final folders = await loadFolders();
    final folderIndex = folders.indexWhere((f) => f.id == folderId);
    if (folderIndex >= 0) {
      final updatedScores = folders[folderIndex].scores.map((s) {
        if (s.id == score.id) {
          return score.copyWith(updatedAt: DateTime.now());
        }
        return s;
      }).toList();
      folders[folderIndex] = folders[folderIndex].copyWith(
        scores: updatedScores,
        updatedAt: DateTime.now(),
      );
      await saveFolders(folders);
    }
  }

  // 폴더에서 악보 업데이트 (별칭)
  Future<void> updateScore(String folderId, ScoreItem score) async {
    await updateScoreInFolder(folderId, score);
  }

  // 폴더에서 악보 삭제
  Future<void> deleteScoreFromFolder(String folderId, String scoreId) async {
    final folders = await loadFolders();
    final folderIndex = folders.indexWhere((f) => f.id == folderId);
    if (folderIndex >= 0) {
      final updatedScores = folders[folderIndex].scores
          .where((s) => s.id != scoreId)
          .toList();
      folders[folderIndex] = folders[folderIndex].copyWith(
        scores: updatedScores,
        updatedAt: DateTime.now(),
      );
      await saveFolders(folders);
    }
  }

  // 악보 이름 수정
  Future<void> updateScoreName(
    String folderId,
    String scoreId,
    String newName,
  ) async {
    final folders = await loadFolders();
    final folderIndex = folders.indexWhere((f) => f.id == folderId);
    if (folderIndex >= 0) {
      final updatedScores = folders[folderIndex].scores.map((s) {
        if (s.id == scoreId) {
          return s.copyWith(name: newName, updatedAt: DateTime.now());
        }
        return s;
      }).toList();
      folders[folderIndex] = folders[folderIndex].copyWith(
        scores: updatedScores,
        updatedAt: DateTime.now(),
      );
      await saveFolders(folders);
    }
  }

  // 악보 접근 시간 업데이트
  Future<void> updateScoreAccessTime(String folderId, String scoreId) async {
    final folders = await loadFolders();
    final folderIndex = folders.indexWhere((f) => f.id == folderId);
    if (folderIndex >= 0) {
      final updatedScores = folders[folderIndex].scores.map((s) {
        if (s.id == scoreId) {
          return s.copyWith(lastAccessedAt: DateTime.now());
        }
        return s;
      }).toList();
      folders[folderIndex] = folders[folderIndex].copyWith(
        scores: updatedScores,
      );
      await saveFolders(folders);
    }
  }

  // 파일 존재 여부 확인 및 정리
  Future<void> cleanupMissingFiles() async {
    final folders = await loadFolders();
    bool needsUpdate = false;

    for (var folder in folders) {
      final validScores = <ScoreItem>[];
      for (var score in folder.scores) {
        final file = File(score.filePath);
        if (await file.exists()) {
          validScores.add(score);
        } else {
          needsUpdate = true;
        }
      }
      if (needsUpdate) {
        await updateFolder(folder.copyWith(scores: validScores));
      }
    }
  }
}

