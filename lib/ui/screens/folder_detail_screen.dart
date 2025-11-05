import 'package:flutter/material.dart';
import 'dart:io';
import '../../models/folder.dart';
import '../../models/score_item.dart';
import '../../models/score_type.dart';
import '../../services/folder_service.dart';
import '../../services/file_picker_service.dart';
import '../../services/permission_service.dart';
import '../../utils/file_utils.dart';
import '../../services/thumbnail_service.dart';
import 'score_detail_screen.dart';
import '../widgets/edit_score_name_dialog.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../../state/score_provider.dart';

class FolderDetailScreen extends StatefulWidget {
  final Folder folder;
  final VoidCallback onFolderUpdated;

  const FolderDetailScreen({
    super.key,
    required this.folder,
    required this.onFolderUpdated,
  });

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  final FolderService _folderService = FolderService();
  final FilePickerService _filePickerService = FilePickerService();
  final _uuid = const Uuid();
  late Folder _folder;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _folder = widget.folder;
    _loadFolder();
  }

  Future<void> _loadFolder() async {
    final folders = await _folderService.loadFolders();
    final updatedFolder = folders.firstWhere(
      (f) => f.id == widget.folder.id,
      orElse: () => widget.folder,
    );
    setState(() {
      _folder = updatedFolder;
    });
  }

  Future<void> _addScore() async {
    // 🔥 CRITICAL: 저장소 권한 확인 및 요청 (갤럭시 탭 등 실제 기기에서 필수)
    final hasPermission = await PermissionService.checkStoragePermission();
    if (!hasPermission) {
      if (!mounted) return;
      
      debugPrint('FolderDetailScreen: _addScore - Storage permission not granted, requesting...');
      final granted = await PermissionService.requestStoragePermission(context);
      if (!granted) {
        debugPrint('FolderDetailScreen: _addScore - Storage permission denied');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('저장소 접근 권한이 필요합니다. 설정에서 권한을 허용해주세요.'),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }
    }
    debugPrint('FolderDetailScreen: _addScore - Storage permission granted');

    final filePaths = await _filePickerService.pickPdfOrImages();
    if (filePaths != null && filePaths.isNotEmpty && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 파일을 앱의 영구 저장소로 복사 (앱 재시작 후에도 접근 가능하도록)
        final copiedPaths = await FileUtils.copyFilesToPermanentStorage(filePaths);
        
        // 파일 타입 결정
        final ScoreType type = copiedPaths[0].toLowerCase().endsWith('.pdf')
            ? ScoreType.pdf
            : ScoreType.image;
        
        // 파일명 생성 (다중 이미지인 경우 첫 번째 파일명 사용)
        final fileName = FileUtils.getFileName(copiedPaths[0]);
        final displayName = copiedPaths.length > 1
            ? '$fileName (${copiedPaths.length}장)'
            : fileName;
        
        // 미리보기 이미지 생성 (첫 번째 파일 사용)
        final thumbnailPath = await ThumbnailService.generateThumbnail(copiedPaths[0]);
        
        final score = ScoreItem(
          id: _uuid.v4(),
          folderId: _folder.id,
          name: displayName,
          filePaths: copiedPaths, // 복사된 경로 사용
          type: type,
          thumbnailPath: thumbnailPath,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          useAI: true,
        );

        await _folderService.addScoreToFolder(_folder.id, score);
        _loadFolder();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('악보가 추가되었습니다 (${copiedPaths.length}개 파일)')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _editScoreName(ScoreItem score) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => EditScoreNameDialog(initialName: score.name),
    );

    if (result != null && result.isNotEmpty && mounted) {
      await _folderService.updateScoreName(_folder.id, score.id, result);
      _loadFolder();
    }
  }

  Future<void> _deleteScore(ScoreItem score) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('악보 삭제'),
        content: Text('${score.name}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _folderService.deleteScoreFromFolder(_folder.id, score.id);
      _loadFolder();
    }
  }

  Future<void> _openScore(ScoreItem score) async {
    // BuildContext를 먼저 저장 (async gap 방지)
    if (!mounted) return;
    
    // 접근 시간 업데이트
    await _folderService.updateScoreAccessTime(_folder.id, score.id);
    if (!mounted) return;
    
    // 파일 존재 확인 (첫 번째 파일만 확인)
    if (score.filePaths.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('파일을 찾을 수 없습니다')),
      );
      return;
    }
    
    final firstFilePath = score.filePaths[0];
    final file = File(firstFilePath);
    if (!await file.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('파일을 찾을 수 없습니다')),
      );
      return;
    }
    if (!mounted) return;

    // ScoreProvider 설정
    final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);
    
    scoreProvider.selectedFile = file;
    scoreProvider.filePath = score.filePaths[0];
    scoreProvider.filePaths = score.filePaths;
    scoreProvider.scoreType = score.type;
    scoreProvider.setCurrentPage(0);

    // 저장된 분석 결과 또는 수동 입력 로드
    // 저장된 수동 입력 로드
    if (score.manualInput != null) {
      scoreProvider.manualInput = score.manualInput;
    }
    if (!mounted) return;

    // 악보 상세 설정 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScoreDetailScreen(
          folderId: _folder.id,
          score: score,
          onScoreUpdated: _loadFolder,
        ),
      ),
    ).then((_) {
      if (mounted) {
        _loadFolder();
      }
    });
  }

  Future<void> _openScoreSettings(ScoreItem score) async {
    // 상세 설정 화면으로 이동
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScoreDetailScreen(
            folderId: _folder.id,
            score: score,
            onScoreUpdated: _loadFolder,
          ),
        ),
      ).then((_) => _loadFolder());
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', ''), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(_folder.color);

    return Scaffold(
      appBar: AppBar(
        title: Text(_folder.name),
        backgroundColor: color,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _isLoading ? null : _addScore,
            tooltip: '악보 추가',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _folder.scores.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_note_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '악보가 없습니다',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _addScore,
                        icon: const Icon(Icons.add),
                        label: const Text('악보 추가'),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _folder.scores.length,
                  itemBuilder: (context, index) {
                    final score = _folder.scores[index];
                    return _ScoreCard(
                      score: score,
                      color: color,
                      onTap: () => _openScore(score),
                      onEdit: () => _editScoreName(score),
                      onSettings: () => _openScoreSettings(score),
                      onDelete: () => _deleteScore(score),
                    );
                  },
                ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final ScoreItem score;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onSettings;
  final VoidCallback onDelete;

  const _ScoreCard({
    required this.score,
    required this.color,
    required this.onTap,
    required this.onEdit,
    required this.onSettings,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 미리보기 이미지
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: score.thumbnailPath != null &&
                        File(score.thumbnailPath!).existsSync()
                    ? Image.file(
                        File(score.thumbnailPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
            // 악보 이름 및 메뉴
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      score.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'settings') {
                        onSettings();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('이름 수정'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings, size: 20),
                            SizedBox(width: 8),
                            Text('상세설정'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('삭제', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.music_note,
        size: 48,
        color: Colors.grey[400],
      ),
    );
  }
}

