import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/timer_provider.dart';
import '../../state/score_provider.dart';
import '../../services/feedback_service.dart';
import '../../services/preferences_service.dart';
import '../widgets/countdown_overlay.dart';
import '../widgets/score_viewer.dart';

class TimerControls extends StatelessWidget {
  final VoidCallback? onStartFullScreen;
  
  const TimerControls({super.key, this.onStartFullScreen});

  @override
  Widget build(BuildContext context) {
    return Consumer2<TimerProvider, ScoreProvider>(
      builder: (context, timerProvider, scoreProvider, child) {
        final timerState = timerProvider.state;
        final pages = scoreProvider.currentPages;
        final autoFlipEnabled = timerProvider.autoFlipEnabled;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 시작/일시정지 버튼
                  SizedBox(
                    height: 48, // 최소 터치 영역
                    child: ElevatedButton.icon(
                      onPressed: pages.isEmpty
                          ? null
                          : () {
                            if (timerState == TimerState.idle) {
                              // 전체화면 모드로 전환
                              if (onStartFullScreen != null) {
                                onStartFullScreen!();
                              }
                              
                              // 타이머 시작
                              timerProvider.onPageFlip = () async {
                                // 페이지 넘김 콜백
                                await _handlePageFlip(context, timerProvider, scoreProvider);
                              };
                              timerProvider.onPageChanged = (pageIndex) {
                                scoreProvider.setCurrentPage(pageIndex);
                              };
                              timerProvider.start(
                                pages: pages,
                                startPageIndex: scoreProvider.currentPage,
                                autoFlip: autoFlipEnabled,
                              );
                            } else if (timerState == TimerState.running) {
                              // 일시정지
                              timerProvider.pause();
                            } else if (timerState == TimerState.paused) {
                              // 재개
                              timerProvider.resume();
                            }
                          },
                    icon: Icon(
                      timerState == TimerState.running
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                      label: Text(
                        timerState == TimerState.running
                            ? '일시정지'
                            : timerState == TimerState.paused
                                ? '재시작'
                                : '시작',
                      ),
                    ),
                  ),

                  // 초기화 버튼
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      onPressed: timerState == TimerState.idle
                          ? null
                          : () {
                              timerProvider.stop();
                              scoreProvider.setCurrentPage(0);
                            },
                      icon: const Icon(Icons.stop),
                      tooltip: '초기화',
                    ),
                  ),

                  // 자동 넘김 토글
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            autoFlipEnabled ? '자동 넘김' : '수동 모드',
                            style: TextStyle(
                              color: autoFlipEnabled 
                                  ? null 
                                  : Colors.orange[700],
                              fontWeight: autoFlipEnabled 
                                  ? FontWeight.normal 
                                  : FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Semantics(
                            label: '자동 넘김',
                            value: autoFlipEnabled ? '켜짐' : '꺼짐',
                            child: Switch(
                              value: autoFlipEnabled,
                              onChanged: (value) {
                                timerProvider.setAutoFlip(value);
                              },
                            ),
                          ),
                        ],
                      ),
                      if (!autoFlipEnabled)
                        Text(
                          '타이머만 작동',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange[700],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handlePageFlip(
    BuildContext context,
    TimerProvider timerProvider,
    ScoreProvider scoreProvider,
  ) async {
    // 카운트다운 표시 (설정에 따라)
    final prefs = PreferencesService();
    final settings = await prefs.loadAppSettings();
    
    if (!context.mounted) return;
    
    if (settings.showCountdown) {
      // 카운트다운 표시 (1초)
      await _showCountdown(context, () async {
        if (!context.mounted) return;
        await _performPageFlip(context, timerProvider, scoreProvider);
      });
    } else {
      await _performPageFlip(context, timerProvider, scoreProvider);
    }
  }

  Future<void> _showCountdown(
    BuildContext context,
    VoidCallback onComplete,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => CountdownOverlay(
        seconds: 1,
        onComplete: () {
          Navigator.pop(context);
          onComplete();
        },
      ),
    );
  }

  Future<void> _performPageFlip(
    BuildContext context,
    TimerProvider timerProvider,
    ScoreProvider scoreProvider,
  ) async {
    // 피드백 재생
    FeedbackService.playPageFlipFeedback();

    // ScoreViewer에 페이지 넘김 신호 전송
    // GlobalKey를 통해 ScoreViewer의 nextPageIndex() 호출
    final scoreViewerKey = scoreProvider.scoreViewerKey;
    if (scoreViewerKey?.currentState != null) {
      (scoreViewerKey!.currentState as ScoreViewerState).nextPageIndex();
    }

    // ScoreProvider의 현재 페이지 업데이트
    final newPageIndex = timerProvider.currentPageIndex;
    if (newPageIndex < scoreProvider.currentPages.length) {
      scoreProvider.setCurrentPage(newPageIndex);
    }
  }
}
