import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../models/bookmark.dart';
import '../../services/bookmark_service.dart';
import '../../state/score_provider.dart';
import 'score_viewer_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final BookmarkService _bookmarkService = BookmarkService();
  List<Bookmark> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _isLoading = true;
    });

    final bookmarks = await _bookmarkService.getValidBookmarks();
    setState(() {
      _bookmarks = bookmarks;
      _isLoading = false;
    });
  }

  Future<void> _deleteBookmark(Bookmark bookmark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('북마크 삭제'),
        content: Text('${bookmark.fileName}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _bookmarkService.deleteBookmark(bookmark.id);
      _loadBookmarks();
    }
  }

  Future<void> _loadBookmark(Bookmark bookmark) async {
    // 파일 존재 확인
    final file = File(bookmark.filePath);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파일을 찾을 수 없습니다')),
        );
      }
      _loadBookmarks(); // 유효하지 않은 북마크 제거
      return;
    }

    if (!mounted) return;
    
    final provider = Provider.of<ScoreProvider>(context, listen: false);
    
    // 북마크 설정 적용
    provider.updateManualInput(bookmark.lastUsedSettings);
    
    // 파일 로드
    provider.scoreViewerKey = null; // 재설정을 위해
    await provider.selectFileAndAnalyze(file);
    
    // 접근 시간 업데이트
    await _bookmarkService.updateBookmarkAccessTime(bookmark.id);
    
    if (mounted) {
      Navigator.pop(context); // 북마크 화면 닫기
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ScoreViewerScreen()),
      );
    }
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}분 전';
      }
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('북마크'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '저장된 북마크가 없습니다',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _bookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = _bookmarks[index];
                    return ListTile(
                      leading: const Icon(Icons.music_note),
                      title: Text(bookmark.fileName),
                      subtitle: Text(
                        '${_formatTimestamp(bookmark.lastAccessedAt)} • BPM: ${bookmark.lastUsedSettings.tempo}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteBookmark(bookmark),
                        tooltip: '삭제',
                      ),
                      onTap: () => _loadBookmark(bookmark),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    );
                  },
                ),
    );
  }
}

