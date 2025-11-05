import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:async';
import '../widgets/score_viewer.dart';
import '../widgets/timer_progress_bar.dart';
import '../widgets/analysis_info_card.dart';
import '../widgets/page_countdown.dart';
import '../widgets/measure_countdown.dart';
import '../../state/score_provider.dart';
import '../../state/timer_provider.dart';
import '../../services/folder_service.dart';
import '../../services/file_picker_service.dart';
import '../../services/app_lifecycle_service.dart';
import '../../services/feedback_service.dart';
import '../../models/score_item.dart';
import '../../models/score_type.dart';
import '../../models/manual_input.dart';
import '../../utils/time_calculator.dart';
import '../../utils/file_utils.dart';
import '../../services/permission_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'manual_input_screen.dart';
import 'settings_screen.dart';

class ScoreDetailScreen extends StatefulWidget {
  final String folderId;
  final ScoreItem score;
  final VoidCallback onScoreUpdated;

  const ScoreDetailScreen({
    super.key,
    required this.folderId,
    required this.score,
    required this.onScoreUpdated,
  });

  @override
  State<ScoreDetailScreen> createState() => _ScoreDetailScreenState();
}

class _ScoreDetailScreenState extends State<ScoreDetailScreen>
    with WidgetsBindingObserver {
  final FolderService _folderService = FolderService();
  final FilePickerService _filePickerService = FilePickerService();
  final GlobalKey<ScoreViewerState> _scoreViewerKey = GlobalKey<ScoreViewerState>();
  AppLifecycleService? _lifecycleService;
  bool _isLoading = false;
  bool _isPlayerMode = false;
  // [TODO] 악보 이름 즉시 반영을 위한 로컬 상태
  late String _currentScoreName;
  // [요구사항 4] 플레이어 UI 오버레이: 컨트롤 바 표시 여부 상태 변수
  bool _controlsVisible = true; // 컨트롤 바 표시 여부 (기본값 true)
  // [요구사항 6-9] 오른쪽 위 1마디 카운트다운 표시 여부
  bool _isMeasureCountdownVisible = false;
  // [요구사항 4] 3초 후 UI 자동 숨김 타이머
  Timer? _autoHideTimer;
  // [요구사항 6] 1마디 카운트다운 완료 여부
  bool _measureCountdownComplete = false;

  @override
  void initState() {
    super.initState();
    // [TODO] 악보 이름 로컬 상태 초기화
    _currentScoreName = widget.score.name;
    WidgetsBinding.instance.addObserver(this);
    
    // [TODO 6-1] TimerProvider 콜백 설정 (initState에서)
    // 초기 콜백 설정 (나중에 _startPlayerFromCurrent에서 다시 설정됨)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timerProvider = Provider.of<TimerProvider>(context, listen: false);
      final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);
      
      // [TODO 81-83] timerProvider.onPageFlip = _handlePageFlip; (직접 연결)
      timerProvider.onPageFlip = () async {
        debugPrint('ScoreDetailScreen: initState - onPageFlip callback triggered');
        await _handlePageFlip(timerProvider, scoreProvider);
      };
      
      // [TODO 85] timerProvider.onPageChanged = (page) => scoreProvider.setCurrentPage(page); (직접 연결)
      timerProvider.onPageChanged = (page) {
        debugPrint('ScoreDetailScreen: initState - onPageChanged callback - pageIndex: $page');
        scoreProvider.setCurrentPage(page);
      };
      
      debugPrint('ScoreDetailScreen: initState - TimerProvider callbacks initialized');
      debugPrint('ScoreDetailScreen: initState - Callbacks: onPageFlip=${timerProvider.onPageFlip != null}, onPageChanged=${timerProvider.onPageChanged != null}');
    });
    
    _loadScore();
  }

  @override
  void didUpdateWidget(ScoreDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // [TODO] widget.score가 변경될 때 로컬 상태 동기화
    if (oldWidget.score.name != widget.score.name) {
      _currentScoreName = widget.score.name;
    }
  }

  @override
  void dispose() {
    // 타이머 완전히 중지
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    timerProvider.stop();
    
    // 🔥 CRITICAL: dispose 시 Wakelock 비활성화 (메모리 누수 방지)
    // TODO.md 요구사항: dispose 메서드에서 timerProvider.stop() 호출한 직후, Wakelock.disable()을 다시 한번 호출
    // 화면을 나갈 때 Wakelock이 확실히 꺼지도록 보장
    try {
      WakelockPlus.disable();
      debugPrint('ScoreDetailScreen: dispose - Wakelock disabled (after timerProvider.stop())');
    } catch (e) {
      debugPrint('ScoreDetailScreen: dispose - Failed to disable wakelock: $e');
    }
    
    _autoHideTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (_lifecycleService != null) {
      WidgetsBinding.instance.removeObserver(_lifecycleService!);
    }
    super.dispose();
  }

  Future<void> _loadScore() async {
    setState(() {
      _isLoading = true;
    });

    // 🔥 CRITICAL: 저장소 권한 확인 및 요청 (갤럭시 탭 등 실제 기기에서 필수)
    final hasPermission = await PermissionService.checkStoragePermission();
    if (!hasPermission) {
      if (!mounted) return;
      
      debugPrint('ScoreDetailScreen: _loadScore - Storage permission not granted, requesting...');
      final granted = await PermissionService.requestStoragePermission(context);
      if (!granted) {
        debugPrint('ScoreDetailScreen: _loadScore - Storage permission denied');
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('저장소 접근 권한이 필요합니다. 설정에서 권한을 허용해주세요.'),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }
    }
    debugPrint('ScoreDetailScreen: _loadScore - Storage permission granted');

    if (!mounted) return;
    final provider = Provider.of<ScoreProvider>(context, listen: false);
    provider.scoreViewerKey = _scoreViewerKey;

    // 파일 존재 확인
    if (widget.score.filePaths.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파일을 찾을 수 없습니다')),
        );
        Navigator.pop(context);
      }
      return;
    }
    
    final firstFile = File(widget.score.filePaths[0]);
    if (!await firstFile.exists()) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파일을 찾을 수 없습니다')),
        );
        Navigator.pop(context);
      }
      return;
    }

    // 파일 로드
    provider.selectedFile = firstFile;
    provider.filePath = widget.score.filePaths[0];
    provider.filePaths = widget.score.filePaths;
    provider.scoreType = widget.score.type;
    provider.setCurrentPage(0);

    // 저장된 수동 입력 로드 또는 기본값으로 초기화
    if (widget.score.manualInput != null) {
      provider.manualInput = widget.score.manualInput;
    } else {
      // manualInput이 없으면 기본값으로 초기화
      final pageCount = widget.score.type == ScoreType.pdf ? 1 : widget.score.filePaths.length;
      final defaultManualInput = ManualInput(
        tempo: 120,
        timeSignature: '4/4',
        pages: List.generate(
          pageCount,
          (index) => PageInput(
            page: index + 1,
            measures: 16, // 기본값 16마디
            repeat: false,
          ),
        ),
      );
      provider.manualInput = defaultManualInput;
      // 기본값을 ScoreItem에도 저장
      final updatedScore = widget.score.copyWith(
        manualInput: defaultManualInput,
      );
      await _folderService.updateScore(widget.folderId, updatedScore);
      widget.onScoreUpdated();
    }

    // 앱 생명주기 서비스 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timerProvider = Provider.of<TimerProvider>(context, listen: false);
      _lifecycleService = AppLifecycleService(timerProvider);
      WidgetsBinding.instance.addObserver(_lifecycleService!);
    });

    setState(() {
      _isLoading = false;
    });

    // 접근 시간 업데이트
    await _folderService.updateScoreAccessTime(
      widget.folderId,
      widget.score.id,
    );
  }

  Future<void> _saveScoreSettings() async {
    final provider = Provider.of<ScoreProvider>(context, listen: false);
    
    final updatedScore = widget.score.copyWith(
      useAI: false,
      analysisResult: null,
      manualInput: provider.manualInput,
      updatedAt: DateTime.now(),
    );

    await _folderService.updateScore(
      widget.folderId,
      updatedScore,
    );

    widget.onScoreUpdated();
  }

  Future<void> _editScoreName() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _currentScoreName);
        return AlertDialog(
          title: const Text('파일 이름 변경'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '파일 이름을 입력하세요',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(context, controller.text.trim());
                }
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty && mounted) {
      // [TODO] 로컬 상태 즉시 업데이트하여 화면에 반영
      setState(() {
        _currentScoreName = result;
      });
      // 백그라운드에서 파일 시스템 업데이트
      await _folderService.updateScoreName(widget.folderId, widget.score.id, result);
      widget.onScoreUpdated();
    }
  }

  void _openManualInput() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManualInputScreen()),
    ).then((_) => _saveScoreSettings());
  }

  /// [TODO 3-4] 배경 이미지 추가: 갤러리에서 이미지 선택하여 미리보기로 설정
  Future<void> _addThumbnailImage() async {
    try {
      // 갤러리에서 이미지 파일 선택
      final filePath = await _filePickerService.pickImageFile();
      
      if (filePath != null && mounted) {
        // 파일을 앱의 영구 저장소로 복사
        final fileName = FileUtils.getFileName(filePath);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final uniqueFileName = 'thumb-$timestamp-$fileName';
        final copiedPath = await FileUtils.copyToPermanentStorage(filePath, uniqueFileName);
        
        // ScoreItem 업데이트 (thumbnailPath 설정)
        final updatedScore = widget.score.copyWith(
          thumbnailPath: copiedPath, // 복사된 경로 사용
          updatedAt: DateTime.now(),
        );
        
        // 폴더 서비스를 통해 저장
        await _folderService.updateScoreInFolder(widget.folderId, updatedScore);
        
        // 상위 위젯에 변경 사항 알림
        widget.onScoreUpdated();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('배경 이미지가 추가되었습니다')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }

  void _openAppSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  // [참고] 페이지별 마디수 설정은 설정 메뉴에서만 접근하므로 현재 미사용
  // ignore: unused_element
  void _showPageEditDialog(BuildContext context, ScoreProvider provider, PageInput page) {
    final measuresController = TextEditingController(text: page.measures.toString());
    bool repeat = page.repeat;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${page.page}페이지 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: measuresController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '마디 수 (0-200)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('반복'),
              value: repeat,
              onChanged: (value) {
                repeat = value ?? false;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final measures = int.tryParse(measuresController.text) ?? page.measures;
              if (measures >= 0 && measures <= 200) {
                provider.updatePage(page.page, measures, repeat);
                _saveScoreSettings();
                Navigator.pop(context);
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  /// [TODO 6-8] '처음부터' 버튼: 첫 페이지로 이동 후 시작
  void _startPlayerFromBeginning() {
    final provider = Provider.of<ScoreProvider>(context, listen: false);
    
    // 첫 페이지로 이동
    const firstPage = 0;
    provider.setCurrentPage(firstPage);
    _scoreViewerKey.currentState?.goToPageIndex(firstPage);
    
    // 현재 페이지에서 시작하는 로직 호출
    _startPlayerFromCurrent();
  }
  
  /// [TODO 6-8] '지금부터' 버튼: 현재 페이지에서 시작
  /// 기존 _startPlayer() 로직을 그대로 사용
  Future<void> _startPlayerFromCurrent() async {
    final provider = Provider.of<ScoreProvider>(context, listen: false);
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    
    // manualInput이 없으면 기본값으로 초기화
    if (provider.manualInput == null) {
      debugPrint('ScoreDetailScreen: _startPlayerFromCurrent - manualInput is null, initializing...');
      
      // 페이지 수 계산 (PDF는 일단 1로 설정, 이미지는 파일 개수)
      final pageCount = widget.score.type == ScoreType.pdf ? 1 : widget.score.filePaths.length;
      final defaultManualInput = ManualInput(
        tempo: 120,
        timeSignature: '4/4',
        pages: List.generate(
          pageCount,
          (index) => PageInput(
            page: index + 1,
            measures: 16, // 기본값 16마디
            repeat: false,
          ),
        ),
      );
      
      provider.manualInput = defaultManualInput;
      
      // ScoreItem에도 저장
      final updatedScore = widget.score.copyWith(
        manualInput: defaultManualInput,
      );
      _folderService.updateScore(widget.folderId, updatedScore).then((_) {
        widget.onScoreUpdated();
      });
    }
    
    // [요구사항 3] ScoreProvider에서 currentPages (페이지별 시간 목록)를 가져옴
    final pages = provider.currentPages;
    
    // 페이지 정보 검증
    if (pages.isEmpty) {
      debugPrint('ScoreDetailScreen: _startPlayerFromCurrent - pages is still empty after initialization!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('페이지 정보가 없습니다. 악보 설정을 먼저 완료해주세요.')),
        );
      }
      return;
    }
    
    debugPrint('ScoreDetailScreen: _startPlayerFromCurrent - pages count: ${pages.length}, startPageIndex: ${provider.currentPage}');
    
    // 타이머가 이미 실행 중이면 완전히 중지 및 리셋
    if (timerProvider.state != TimerState.idle) {
      debugPrint('ScoreDetailScreen: _startPlayerFromCurrent - stopping existing timer');
      timerProvider.stop();
    }
    
    // 🔥 CRITICAL: 타이머 콜백 설정 (타이머 시작 전에 반드시 설정!)
    // 갤럭시 탭 S10+에서도 작동하도록 명시적으로 설정
    timerProvider.onPageFlip = () async {
      debugPrint('ScoreDetailScreen: _startPlayerFromCurrent - onPageFlip callback triggered');
      await _handlePageFlip(timerProvider, provider);
    };
    timerProvider.onPageChanged = (pageIndex) {
      debugPrint('ScoreDetailScreen: _startPlayerFromCurrent - onPageChanged callback - pageIndex: $pageIndex');
      // TimerProvider의 currentPageIndex가 변경될 때 ScoreProvider도 동기화
      provider.setCurrentPage(pageIndex);
    };
    
    debugPrint('ScoreDetailScreen: _startPlayerFromCurrent - Callbacks set: onPageFlip=${timerProvider.onPageFlip != null}, onPageChanged=${timerProvider.onPageChanged != null}');
    
    // [요구사항 7] 1마디 시간 계산 (BPM과 박자표에 맞춘)
    final manualInput = provider.manualInput!;
    final measureDuration = TimeCalculator.calculateMeasureDuration(
      manualInput.tempo,
      manualInput.timeSignature,
    );
    
    debugPrint('ScoreDetailScreen: _startPlayerFromCurrent - measureDuration: ${measureDuration}s');
    
    // [요구사항 3] 플레이어 모드로 진입
    setState(() {
      _isPlayerMode = true;
      _controlsVisible = true; // 처음에는 버튼 표시
      _isMeasureCountdownVisible = true; // 오른쪽 위 카운트다운 표시
      _measureCountdownComplete = false; // 1마디 카운트다운 미완료
    });
    
    // 🔥 CRITICAL: 배터리 최적화 방지 - 화면이 꺼지지 않도록 Wakelock 활성화
    // 갤럭시 탭 등 삼성 기기에서 타이머가 멈추는 것을 방지
    try {
      await WakelockPlus.enable();
      debugPrint('ScoreDetailScreen: _startPlayerFromCurrent - Wakelock enabled');
    } catch (e) {
      debugPrint('ScoreDetailScreen: _startPlayerFromCurrent - Failed to enable wakelock: $e');
    }
    
    // [요구사항 4] 3초 후 UI 자동 숨김
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlayerMode) {
        setState(() {
          _controlsVisible = false;
        });
      }
    });
  }
  
  /// [요구사항 9] 1마디 카운트다운 완료 후 호출되는 콜백
  /// 오른쪽 위 카운트다운이 끝나면 왼쪽 위 본 카운트다운(TimerProvider)을 시작
  void _onMeasureCountdownComplete() {
    final provider = Provider.of<ScoreProvider>(context, listen: false);
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    
    debugPrint('ScoreDetailScreen: _onMeasureCountdownComplete - 1마디 카운트다운 완료, TimerProvider.start() 호출');
    
    // [요구사항 9] 오른쪽 위 카운트다운 숨김
    setState(() {
      _isMeasureCountdownVisible = false;
      _measureCountdownComplete = true;
    });
    
    // 🔥 CRITICAL: 콜백을 다시 한번 확실히 설정 (타이머 시작 전에!)
    timerProvider.onPageFlip = () async {
      debugPrint('ScoreDetailScreen: _onMeasureCountdownComplete - onPageFlip callback triggered');
      await _handlePageFlip(timerProvider, provider);
    };
    timerProvider.onPageChanged = (pageIndex) {
      debugPrint('ScoreDetailScreen: _onMeasureCountdownComplete - onPageChanged callback - pageIndex: $pageIndex');
      provider.setCurrentPage(pageIndex);
    };
    
    debugPrint('ScoreDetailScreen: _onMeasureCountdownComplete - Callbacks confirmed: onPageFlip=${timerProvider.onPageFlip != null}, onPageChanged=${timerProvider.onPageChanged != null}');
    
    // [요구사항 9] 왼쪽 위 본 카운트다운(TimerProvider) 시작
    final pages = provider.currentPages;
    debugPrint('ScoreDetailScreen: _onMeasureCountdownComplete - Starting timer with pages: ${pages.length}, startPageIndex: ${provider.currentPage}');
    
    timerProvider.start(
      pages: pages,
      startPageIndex: provider.currentPage.clamp(0, pages.length - 1),
      autoFlip: timerProvider.autoFlipEnabled,
    );
    
    debugPrint('ScoreDetailScreen: _onMeasureCountdownComplete - TimerProvider started, state: ${timerProvider.state}');
  }

  /// [TODO 87] _handlePageFlip 함수가 _scoreViewerKey.currentState!.nextPageIndex()를 호출
  /// TimerProvider의 onPageFlip 콜백에서 호출되어 페이지를 넘김
  Future<void> _handlePageFlip(
    TimerProvider timerProvider,
    ScoreProvider scoreProvider,
  ) async {
    final targetPageIndex = timerProvider.currentPageIndex;
    debugPrint('ScoreDetailScreen: _handlePageFlip called - targetPageIndex: $targetPageIndex');
    
    // ScoreViewer의 state가 null인지 확인
    if (_scoreViewerKey.currentState == null) {
      debugPrint('ScoreDetailScreen: _handlePageFlip - ERROR: _scoreViewerKey.currentState is null!');
      return;
    }
    
    // 파일 경로 검증
    if (widget.score.filePaths.isEmpty) {
      debugPrint('ScoreDetailScreen: _handlePageFlip - ERROR: filePaths is empty!');
      return;
    }
    
    try {
      // TimerProvider에서 이미 currentPageIndex를 업데이트했으므로,
      // goToPageIndex를 사용하여 해당 페이지로 이동
      debugPrint('ScoreDetailScreen: _handlePageFlip - calling goToPageIndex($targetPageIndex)');
      debugPrint('ScoreDetailScreen: _handlePageFlip - score type: ${widget.score.type}');
      debugPrint('ScoreDetailScreen: _handlePageFlip - filePaths count: ${widget.score.filePaths.length}');
      
      // ScoreViewer의 상태 확인
      final scoreViewerState = _scoreViewerKey.currentState!;
      
      // 페이지 범위 검증
      if (widget.score.type == ScoreType.pdf) {
        // PDF는 ScoreViewer 내부에서 _totalPages 확인
        debugPrint('ScoreDetailScreen: _handlePageFlip - PDF type, targetPageIndex: $targetPageIndex');
      } else {
        // 이미지는 파일 개수 확인
        if (targetPageIndex < 0 || targetPageIndex >= widget.score.filePaths.length) {
          debugPrint('ScoreDetailScreen: _handlePageFlip - ERROR: targetPageIndex ($targetPageIndex) out of range (0-${widget.score.filePaths.length - 1})');
          return;
        }
        debugPrint('ScoreDetailScreen: _handlePageFlip - Image type, targetPageIndex: $targetPageIndex, total: ${widget.score.filePaths.length}');
      }
      
      // 실제 페이지 넘김 실행
      scoreViewerState.goToPageIndex(targetPageIndex);
      
      // ScoreProvider의 현재 페이지도 동기화
      scoreProvider.setCurrentPage(targetPageIndex);
      
      // 피드백 재생
      await FeedbackService.playPageFlipFeedback();
      
      debugPrint('ScoreDetailScreen: _handlePageFlip - page flip completed successfully to page $targetPageIndex');
    } catch (e, stackTrace) {
      debugPrint('ScoreDetailScreen: _handlePageFlip - ERROR: $e');
      debugPrint('ScoreDetailScreen: _handlePageFlip - Stack trace: $stackTrace');
      // 에러가 발생해도 계속 진행 (다음 페이지 타이머는 계속 실행됨)
    }
  }

  void _handlePause() {
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    
    // 타이머 일시정지 (컨트롤 바는 유지)
    timerProvider.pause();
    
    // [요구사항 4] 일시정지 시 자동 숨김 타이머 취소
    _autoHideTimer?.cancel();
  }

  void _handleResume() {
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    
    // 타이머 재개
    timerProvider.resume();
    
    // [요구사항 2] 전체화면 모드 사용 안 함
    
    // [요구사항 4] 컨트롤 바 표시 후 3초 후 숨김
    setState(() {
      _controlsVisible = true;
    });
    
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlayerMode) {
        setState(() {
          _controlsVisible = false;
        });
      }
    });
  }

  void _handleReset() {
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);
    
    // 타이머 완전히 중지 및 리셋
    timerProvider.stop();
    
    // 🔥 CRITICAL: Wakelock 비활성화 (리셋 시 화면이 꺼지도록)
    try {
      WakelockPlus.disable();
      debugPrint('ScoreDetailScreen: _handleReset - Wakelock disabled');
    } catch (e) {
      debugPrint('ScoreDetailScreen: _handleReset - Failed to disable wakelock: $e');
    }
    
    // [요구사항 4] 자동 숨김 타이머 취소
    _autoHideTimer?.cancel();
    
    // 악보 뷰어를 첫 번째 페이지로 이동
    if (_scoreViewerKey.currentState != null) {
      _scoreViewerKey.currentState!.goToPageIndex(0);
    }
    
    // ScoreProvider의 현재 페이지도 리셋
    scoreProvider.setCurrentPage(0);
    
    // [요구사항 4] 리셋 시 컨트롤 바 표시
    setState(() {
      _controlsVisible = true;
      _isMeasureCountdownVisible = false;
      _measureCountdownComplete = false;
    });
  }

  void _handleBack() {
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    
    // 타이머 완전히 중지
    timerProvider.stop();
    
    // 🔥 CRITICAL: Wakelock 비활성화 (배터리 절약)
    // TODO.md 요구사항: _handleBack 함수에서 timerProvider.stop() 호출한 직후, Wakelock.disable()을 다시 한번 호출
    // 화면을 나갈 때 Wakelock이 확실히 꺼지도록 보장
    try {
      WakelockPlus.disable();
      debugPrint('ScoreDetailScreen: _handleBack - Wakelock disabled (after timerProvider.stop())');
    } catch (e) {
      debugPrint('ScoreDetailScreen: _handleBack - Failed to disable wakelock: $e');
    }
    
    // [요구사항 2] SystemUiMode는 변경하지 않음 (전체화면 모드 사용 안 함)
    
    // [요구사항 4] 자동 숨김 타이머 취소
    _autoHideTimer?.cancel();
    
    // 플레이어 모드 종료
    setState(() {
      _isPlayerMode = false;
      _controlsVisible = true;
      _isMeasureCountdownVisible = false;
      _measureCountdownComplete = false;
    });
  }


  // [TODO 5-3] 플레이어 UI 오버레이: 상단 좌측 뒤로 가기 버튼
  Widget _buildTopLeftBackButton() {
    return Align(
      alignment: Alignment.topLeft,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: _handleBack,
              tooltip: '뒤로 가기',
            ),
          ),
        ),
      ),
    );
  }

  // [TODO 5-3] 플레이어 UI 오버레이: 하단 중앙 컨트롤 버튼들 (일시정지/재개, 초기화)
  Widget _buildBottomCenterControls() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Consumer2<TimerProvider, ScoreProvider>(
            builder: (context, timerProvider, scoreProvider, child) {
              final timerState = timerProvider.state;
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 일시정지/재개/시작 버튼
                    IconButton(
                      onPressed: () {
                        if (timerState == TimerState.idle) {
                          _startPlayerFromCurrent();
                        } else if (timerState == TimerState.running) {
                          _handlePause();
                        } else if (timerState == TimerState.paused) {
                          _handleResume();
                        }
                      },
                      icon: Icon(
                        timerState == TimerState.idle
                            ? Icons.play_circle_outline
                            : timerState == TimerState.running
                                ? Icons.pause_circle_outline
                                : Icons.play_circle_outline,
                        color: Colors.white,
                        size: 36,
                      ),
                      tooltip: timerState == TimerState.idle
                          ? '시작'
                          : timerState == TimerState.running
                              ? '일시정지'
                              : '재개',
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // 초기화 버튼
                    IconButton(
                      onPressed: timerState == TimerState.idle
                          ? null
                          : () {
                              _handleReset();
                            },
                      icon: Icon(
                        Icons.refresh,
                        color: timerState == TimerState.idle
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.white,
                        size: 28,
                      ),
                      tooltip: '초기화',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _isPlayerMode ? Theme.of(context).scaffoldBackgroundColor : null,
      appBar: _isPlayerMode ? null : AppBar(
        title: Text(_currentScoreName),
        actions: [
          // 연필 아이콘: 파일 이름 변경
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editScoreName,
            tooltip: '파일 이름 변경',
          ),
          // 톱니 아이콘: BPM, 박자표, 페이지별 마디수 설정 및 앱 설정
          Consumer<ScoreProvider>(
            builder: (context, provider, child) {
              if (provider.filePaths != null && provider.filePaths!.isNotEmpty) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.settings),
                  tooltip: '설정',
                  onSelected: (value) {
                    if (value == 'manual') {
                      _openManualInput();
                    } else if (value == 'thumbnail') {
                      _addThumbnailImage();
                    } else if (value == 'app') {
                      _openAppSettings();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'manual',
                      child: Row(
                        children: [
                          Icon(Icons.music_note, size: 20),
                          SizedBox(width: 8),
                          Text('악보 설정 (BPM, 박자표, 마디수)'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'thumbnail',
                      child: Row(
                        children: [
                          Icon(Icons.image, size: 20),
                          SizedBox(width: 8),
                          Text('배경 이미지 추가'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'app',
                      child: Row(
                        children: [
                          Icon(Icons.settings, size: 20),
                          SizedBox(width: 8),
                          Text('앱 설정'),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<ScoreProvider>(
        builder: (context, provider, child) {
          // 파일이 선택되지 않은 경우
          if (provider.filePaths == null || provider.filePaths!.isEmpty) {
            return const Center(
              child: Text('파일을 불러올 수 없습니다'),
            );
          }

          // 파일이 선택된 경우
          return Stack(
            fit: StackFit.expand,
            children: [
              // [TODO 4-A] 설정 카드: 악보 설정 (BPM, 박자표)
              // _isPlayerMode가 true이면 top: -600 (화면 밖), false이면 top: 0 (원래 위치)
              // Stack에서 먼저 배치하여 악보 뷰어 아래에 있도록 함
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top: _isPlayerMode ? -600 : 0,
                left: 0,
                right: 0,
                bottom: _isPlayerMode ? null : 80, // 시작 버튼 공간 확보
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _isPlayerMode ? 0 : 1,
                  child: Column(
                    children: [
                      // [요구사항 5] 기존 '악보 설정' UI 자리에는 '악보 정보' UI만 표시
                      // '악보 설정' 카드(BPM, 박자표)는 제거하고 설정 메뉴에서만 접근
                      const AnalysisInfoCard(),
                      
                      const SizedBox(height: 8),
                      
                      // 진행률 바 (설정 관련 UI)
                      const TimerProgressBar(),
                      
                      // [요구사항 3] 악보 뷰어를 '악보 정보' 아래에 배치하여 가려지지 않게 함
                      // 플레이어 모드가 아닐 때만 ScoreViewer 렌더링 (GlobalKey 중복 방지)
                      if (!_isPlayerMode)
                        Expanded(
                          child: Consumer<ScoreProvider>(
                            builder: (context, scoreProvider, child) {
                              return ScoreViewer(
                                key: _scoreViewerKey,
                                filePaths: widget.score.filePaths,
                                type: widget.score.type,
                                currentPage: scoreProvider.currentPage,
                                onPageChanged: (page) {
                                  // [TODO 89] ScoreViewer의 onPageChanged 파라미터가 timerProvider.goToPage(page)를 호출하여 수동 스크롤 시 타이머 동기화
                                  final timerProvider = Provider.of<TimerProvider>(context, listen: false);
                                  scoreProvider.setCurrentPage(page);
                                  
                                  // 타이머가 실행 중이고 사용자가 수동으로 페이지를 변경한 경우
                                  if (timerProvider.state == TimerState.running || timerProvider.state == TimerState.paused) {
                                    debugPrint('ScoreDetailScreen: User manually changed page to $page, syncing TimerProvider');
                                    timerProvider.goToPage(page);
                                  }
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // [요구사항 1] 페이지별 마디수 UI 제거됨 - 설정 메뉴(톱니)에서만 접근
              
              // [TODO 6-7] 시작 버튼 두 개: '처음부터', '지금부터' (플레이어 모드가 아닐 때만 표시)
              if (!_isPlayerMode)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _isPlayerMode ? 0 : 1,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: Row(
                        children: [
                          // [TODO 7] '처음부터' 버튼 (초록색)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _startPlayerFromBeginning,
                              icon: const Icon(Icons.refresh),
                              label: const Text(
                                '처음부터',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // [TODO 7] '지금부터' 버튼 (파란색 - 기존 시작 색)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _startPlayerFromCurrent,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text(
                                '지금부터',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // [요구사항 3] 플레이어 모드에서 악보를 화면 중앙에 크게 배치 (이미지 참고)
              // 상단 컨트롤(뒤로가기 + 진행률바)과 하단 컨트롤(일시정지/리셋) 사이에 악보를 배치
              if (_isPlayerMode)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: 80, // 상단 컨트롤 영역 (뒤로가기 + 진행률바)
                  left: 0,
                  right: 0,
                  bottom: 80, // 하단 컨트롤 영역 (일시정지/리셋)
                  child: Consumer<ScoreProvider>(
                    builder: (context, scoreProvider, child) {
                      return ScoreViewer(
                        key: _scoreViewerKey,
                        filePaths: widget.score.filePaths,
                        type: widget.score.type,
                        currentPage: scoreProvider.currentPage,
                        onPageChanged: (page) {
                          // [요구사항 4] 시작버튼 누른 이후에도 임의로 스크롤하여 다음 악보를 볼 수 있어야함
                          final timerProvider = Provider.of<TimerProvider>(context, listen: false);
                          scoreProvider.setCurrentPage(page);
                          
                          // 타이머가 실행 중이고 사용자가 수동으로 페이지를 변경한 경우
                          if (timerProvider.state == TimerState.running || timerProvider.state == TimerState.paused) {
                            debugPrint('ScoreDetailScreen: User manually changed page to $page, syncing TimerProvider');
                            timerProvider.goToPage(page);
                          }
                        },
                      );
                    },
                  ),
                ),
              
              // [요구사항 4] 플레이어 모드에서 악보를 터치하면 UI가 다시 나타나도록
              // 악보 영역 전체에 GestureDetector 배치 (스크롤은 ScoreViewer 내부에서 처리)
              if (_isPlayerMode)
                Positioned(
                  top: 80,
                  left: 0,
                  right: 0,
                  bottom: 80,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      // [요구사항 4] 악보 터치 시 컨트롤 바 다시 표시
                      setState(() {
                        _controlsVisible = true;
                      });
                      
                      // [요구사항 4] 3초 후 다시 숨김
                      _autoHideTimer?.cancel();
                      _autoHideTimer = Timer(const Duration(seconds: 3), () {
                        if (mounted && _isPlayerMode) {
                          setState(() {
                            _controlsVisible = false;
                          });
                        }
                      });
                    },
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              
              // [요구사항 8-9] 오른쪽 위 1마디 카운트다운 (4, 3, 2, 1)
              // 오른쪽 위 카운트다운이 끝나야 왼쪽 위 본 카운트다운이 시작됨
              if (_isPlayerMode && _isMeasureCountdownVisible)
                Consumer<ScoreProvider>(
                  builder: (context, provider, child) {
                    if (provider.manualInput == null) {
                      return const SizedBox.shrink();
                    }
                    
                    final manualInput = provider.manualInput!;
                    final measureDuration = TimeCalculator.calculateMeasureDuration(
                      manualInput.tempo,
                      manualInput.timeSignature,
                    );
                    
                    return MeasureCountdown(
                      measureDuration: measureDuration,
                      onComplete: _onMeasureCountdownComplete,
                    );
                  },
                ),
              
              // [요구사항 9] 왼쪽 위 본 카운트다운 UI: 오른쪽 위 카운트다운이 끝난 후 표시
              // TimerProvider의 상태가 running일 때 왼쪽 상단에 PageCountdown 위젯 표시
              if (_isPlayerMode && _measureCountdownComplete)
                Consumer<TimerProvider>(
                  builder: (context, timerProvider, child) {
                    // 타이머가 실행 중이거나 일시정지 상태일 때 표시
                    if (timerProvider.state == TimerState.running || 
                        timerProvider.state == TimerState.paused) {
                      return const PageCountdown();
                    }
                    return const SizedBox.shrink();
                  },
                ),
              
              // [TODO 5-3] 컨트롤 UI: _isPlayerMode가 true이고 _controlsVisible이 true일 때만 표시
              // '뒤로 가기', '일시정지/재개', '초기화' 버튼이 Stack 위에 오버레이로 나타남
              if (_isPlayerMode && _controlsVisible) _buildTopLeftBackButton(),
              if (_isPlayerMode && _controlsVisible) _buildBottomCenterControls(),
              
              // [TODO 3-4] 오른쪽 아래에 현재페이지/전체페이지수 표시 (옅은 회색)
              if (_isPlayerMode)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Consumer<ScoreProvider>(
                    builder: (context, provider, child) {
                      final currentPage = provider.currentPage + 1; // 0-based -> 1-based
                      // [TODO 5] 전체 페이지 수 계산: PDF는 currentPages.length, 이미지는 filePaths.length
                      final totalPages = widget.score.type == ScoreType.pdf
                          ? provider.currentPages.length
                          : widget.score.filePaths.length;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$currentPage/$totalPages',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

