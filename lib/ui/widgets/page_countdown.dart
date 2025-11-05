import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/timer_provider.dart';

/// 전체화면 모드에서 왼쪽 위에 표시되는 작은 카운트다운 위젯
class PageCountdown extends StatelessWidget {
  const PageCountdown({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        // 타이머가 실행 중이거나 일시정지 상태일 때 표시
        if (timerProvider.state != TimerState.running && 
            timerProvider.state != TimerState.paused) {
          return const SizedBox.shrink();
        }

        final remaining = timerProvider.remainingSeconds;
        final currentPageDuration = timerProvider.currentPageDuration;
        
        // 줄어드는 형식: 남은 시간 비율로 표시 (1.0에서 0.0으로 감소)
        final progress = currentPageDuration > 0 
            ? (remaining / currentPageDuration).clamp(0.0, 1.0)
            : 1.0;

        return Positioned(
          top: 16,
          left: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 게이지 위에 카운트다운 텍스트 (8pt, 남색)
              Text(
                remaining.toStringAsFixed(remaining < 1 ? 1 : 0),
                style: const TextStyle(
                  fontSize: 8, // 8pt
                  fontWeight: FontWeight.w500,
                  color: Colors.indigo, // 남색
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              // 남색 게이지 (줄어드는 형식)
              SizedBox(
                width: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: Colors.indigo.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.indigo, // 남색
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

