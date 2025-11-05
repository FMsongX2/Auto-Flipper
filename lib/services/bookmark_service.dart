import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/bookmark.dart';
import '../models/manual_input.dart';
import 'preferences_service.dart';

class BookmarkService {
  final PreferencesService _preferencesService = PreferencesService();
  final Uuid _uuid = const Uuid();

  // 북마크 추가
  Future<Bookmark> addBookmark({
    required String filePath,
    required String fileName,
    required ManualInput settings,
  }) async {
    final bookmarks = await loadBookmarks();
    final now = DateTime.now().millisecondsSinceEpoch;

    final bookmark = Bookmark(
      id: _uuid.v4(),
      filePath: filePath,
      fileName: fileName,
      lastUsedSettings: settings,
      createdAt: now,
      lastAccessedAt: now,
    );

    // 중복 체크 (같은 파일 경로)
    final existingIndex = bookmarks.indexWhere((b) => b.filePath == filePath);
    if (existingIndex >= 0) {
      // 기존 북마크 업데이트
      bookmarks[existingIndex] = bookmark.copyWith(
        id: bookmarks[existingIndex].id,
        createdAt: bookmarks[existingIndex].createdAt,
      );
    } else {
      bookmarks.add(bookmark);
    }

    await _preferencesService.saveBookmarks(bookmarks);
    return bookmark;
  }

  // 북마크 로드
  Future<List<Bookmark>> loadBookmarks() async {
    return await _preferencesService.loadBookmarks();
  }

  // 북마크 삭제
  Future<void> deleteBookmark(String id) async {
    final bookmarks = await loadBookmarks();
    bookmarks.removeWhere((b) => b.id == id);
    await _preferencesService.saveBookmarks(bookmarks);
  }

  // 북마크 업데이트 (접근 시간)
  Future<void> updateBookmarkAccessTime(String id) async {
    final bookmarks = await loadBookmarks();
    final index = bookmarks.indexWhere((b) => b.id == id);
    if (index >= 0) {
      bookmarks[index] = bookmarks[index].copyWith(
        lastAccessedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _preferencesService.saveBookmarks(bookmarks);
    }
  }

  // 파일 존재 확인
  Future<bool> isFileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // 유효한 북마크만 필터링 (파일이 존재하는 것만)
  Future<List<Bookmark>> getValidBookmarks() async {
    final bookmarks = await loadBookmarks();
    final validBookmarks = <Bookmark>[];

    for (final bookmark in bookmarks) {
      if (await isFileExists(bookmark.filePath)) {
        validBookmarks.add(bookmark);
      }
    }

    // 유효하지 않은 북마크 제거
    if (validBookmarks.length != bookmarks.length) {
      await _preferencesService.saveBookmarks(validBookmarks);
    }

    // 최근 접근 순으로 정렬
    validBookmarks.sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));

    return validBookmarks;
  }
}

