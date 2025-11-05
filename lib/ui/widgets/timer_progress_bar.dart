import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/timer_provider.dart';
import '../../state/score_provider.dart';

class TimerProgressBar extends StatelessWidget {
  const TimerProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<TimerProvider, ScoreProvider>(
      builder: (context, timerProvider, scoreProvider, child) {
        if (timerProvider.state == TimerState.idle) {
          return const SizedBox.shrink();
        }

        final remaining = timerProvider.remainingSeconds;
        final progress = timerProvider.progress;
        final currentPageIndex = timerProvider.currentPageIndex;
        final currentPage = currentPageIndex + 1;
        final totalPages = scoreProvider.currentPages.length;
        final totalProgress = totalPages > 0 
            ? (currentPage / totalPages).clamp(0.0, 1.0)
            : 0.0;

        // 현재 페이지의 마디 정보
        final currentPageInfo = scoreProvider.currentPages.isNotEmpty &&
                currentPageIndex < scoreProvider.currentPages.length
            ? scoreProvider.currentPages[currentPageIndex]
            : null;
        
        // 현재 마디 번호 계산 (대략적인 계산)
        final currentMeasures = currentPageInfo?.measures ?? 0;
        final elapsedMeasures = currentMeasures > 0 && timerProvider.currentPageDuration > 0
            ? ((timerProvider.elapsedSeconds / timerProvider.currentPageDuration) * currentMeasures).round()
            : 0;
        final currentMeasureText = currentMeasures > 0
            ? '마디 ${elapsedMeasures.clamp(0, currentMeasures)}/$currentMeasures'
            : '';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 전체 진행률
              if (totalPages > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '전체 진행률',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '$currentPage/$totalPages 페이지',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              if (totalPages > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LinearProgressIndicator(
                    value: totalProgress,
                    minHeight: 3,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              
              // 현재 페이지 진행률
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '페이지 $currentPage',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (currentMeasureText.isNotEmpty)
                        Text(
                          currentMeasureText,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                        ),
                    ],
                  ),
                  Text(
                    '남은 시간: ${remaining.toStringAsFixed(1)}초',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
