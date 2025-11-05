import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../widgets/score_viewer.dart';
import '../widgets/timer_controls.dart';
import '../widgets/page_countdown.dart';
import '../../services/file_picker_service.dart';
import '../../state/score_provider.dart';
import '../../state/timer_provider.dart';
import '../../services/app_lifecycle_service.dart';

class ScoreViewerScreen extends StatefulWidget {
  const ScoreViewerScreen({super.key});

  @override
  State<ScoreViewerScreen> createState() => _ScoreViewerScreenState();
}

class _ScoreViewerScreenState extends State<ScoreViewerScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final FilePickerService _filePickerService = FilePickerService();
  final GlobalKey<ScoreViewerState> _scoreViewerKey = GlobalKey<ScoreViewerState>();
  AppLifecycleService? _lifecycleService;
  bool _isFullScreen = false;  // 전체화면 모드 상태
  bool _showMinimalUI = false;  // 전체화면 모드에서 최소화된 UI 표시 여부
  late AnimationController _controlsAnimationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 컨트롤 애니메이션 초기화
    _controlsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Provider에 GlobalKey 등록
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ScoreProvider>(context, listen: false);
      provider.scoreViewerKey = _scoreViewerKey;
      
      // 앱 생명주기 서비스 초기화
      final timerProvider = Provider.of<TimerProvider>(context, listen: false);
      
      // 화면 진입 시 타이머가 실행 중이면 초기화
      if (timerProvider.state != TimerState.idle) {
        timerProvider.stop();
      }
      
      _lifecycleService = AppLifecycleService(timerProvider);
      WidgetsBinding.instance.addObserver(_lifecycleService!);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_lifecycleService != null) {
      WidgetsBinding.instance.removeObserver(_lifecycleService!);
    }
    
    // 애니메이션 컨트롤러 해제
    _controlsAnimationController.dispose();
    
    // SystemUiMode 복원
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // 타이머 초기화
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    timerProvider.stop();
    
    super.dispose();
  }

  Future<void> _pickFile() async {
    final filePath = await _filePickerService.pickPdfOrImage();
    if (filePath != null && mounted) {
      final file = File(filePath);
      final provider = Provider.of<ScoreProvider>(context, listen: false);
      provider.scoreViewerKey = _scoreViewerKey;
      await provider.selectFileAndAnalyze(file);
    }
  }
  

  @override
  Widget build(BuildContext context) {
    // 전체화면 모드일 때는 Scaffold 없이 직접 구성
    if (_isFullScreen) {
      // SystemUiMode.immersiveSticky 적용
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      
      return Consumer<ScoreProvider>(
        builder: (context, provider, child) {
          if (provider.filePath == null) {
            // 일반 모드로 복원
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
            return const Scaffold(
              body: Center(
                child: Text('악보 파일을 선택해주세요'),
              ),
            );
          }
          
          return Scaffold(
            backgroundColor: Colors.black,
            body: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                // 전체화면 모드에서 탭 시 최소화된 UI 토글
                if (_isFullScreen) {
                  setState(() {
                    _showMinimalUI = !_showMinimalUI;
                    if (_showMinimalUI) {
                      _controlsAnimationController.forward();
                    } else {
                      _controlsAnimationController.reverse();
                    }
                  });
                  
                  // 3초 후 자동으로 다시 숨김
                  if (_showMinimalUI) {
                    Future.delayed(const Duration(seconds: 3), () {
                      if (mounted && _isFullScreen && _showMinimalUI) {
                        setState(() {
                          _showMinimalUI = false;
                          _controlsAnimationController.reverse();
                        });
                      }
                    });
                  }
                }
              },
              onLongPress: () {
                // 3초간 꾹 누르면 파일 선택 화면으로 이동
                SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                Navigator.pop(context);
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 악보 뷰어 (전체 화면을 완전히 채움)
                  Positioned.fill(
                    child: ScoreViewer.fromSinglePath(
                      key: _scoreViewerKey,
                      provider.filePath!,
                      currentPage: provider.currentPage,
                      onPageChanged: (page) {
                        provider.setCurrentPage(page);
                      },
                    ),
                  ),
                  
                  // 왼쪽 위 카운트다운
                  const PageCountdown(),
                  
                  // 전체화면 모드에서 최소화된 오버레이 UI (중앙에 작게 표시)
                  AnimatedOpacity(
                    opacity: _showMinimalUI ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: !_showMinimalUI,
                      child: Center(
                        child: Consumer<TimerProvider>(
                          builder: (context, timerProvider, child) {
                            return _buildMinimalOverlayUI(context, timerProvider, provider);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
    
    // 일반 모드로 복원
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // 일반 모드일 때는 Scaffold 사용 (뒤로가기 버튼만)
    return Scaffold(
      appBar: AppBar(
        title: const Text('악보 뷰어'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ScoreProvider>(
        builder: (context, provider, child) {
          // 파일이 선택되지 않은 경우
          if (provider.filePath == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.music_note,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '악보 파일을 선택해주세요',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('파일 선택'),
                  ),
                ],
              ),
            );
          }

          // 파일이 선택된 경우
          // 악보 전체화면 + 시작 버튼만 표시
          return Consumer<TimerProvider>(
            builder: (context, timerProvider, child) {
              // 타이머가 실행 중이면 시작 버튼 숨김
              final isTimerRunning = timerProvider.state != TimerState.idle;
              
              return Stack(
                children: [
                  // 악보 뷰어
                  ScoreViewer.fromSinglePath(
                    key: _scoreViewerKey,
                    provider.filePath!,
                    currentPage: provider.currentPage,
                    onPageChanged: (page) {
                      provider.setCurrentPage(page);
                    },
                  ),
                  
                  // 타이머가 실행 중이 아닐 때만 시작 버튼 표시
                  if (!isTimerRunning)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: TimerControls(
                          onStartFullScreen: () {
                            setState(() {
                              _isFullScreen = true;
                              _showMinimalUI = false;
                            });
                          },
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
  
  // 최소화된 오버레이 UI 빌드
  Widget _buildMinimalOverlayUI(BuildContext context, TimerProvider timerProvider, ScoreProvider scoreProvider) {
    final timerState = timerProvider.state;
    final pages = scoreProvider.currentPages;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 일시정지/재생 버튼
          SizedBox(
            width: 56,
            height: 56,
            child: IconButton(
              onPressed: pages.isEmpty
                  ? null
                  : () {
                      if (timerState == TimerState.running) {
                        timerProvider.pause();
                      } else if (timerState == TimerState.paused) {
                        timerProvider.resume();
                      }
                    },
              icon: Icon(
                timerState == TimerState.running
                    ? Icons.pause
                    : Icons.play_arrow,
                color: Colors.white,
                size: 28,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 중지 버튼 (전체화면 해제)
          SizedBox(
            width: 56,
            height: 56,
            child: IconButton(
              onPressed: timerState == TimerState.idle
                  ? null
                  : () {
                      timerProvider.stop();
                      scoreProvider.setCurrentPage(0);
                      // 전체화면 모드 해제
                      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                      setState(() {
                        _isFullScreen = false;
                        _showMinimalUI = false;
                        _controlsAnimationController.reverse();
                      });
                    },
              icon: const Icon(
                Icons.stop,
                color: Colors.white,
                size: 28,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

