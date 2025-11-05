import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/score_provider.dart';
import '../../utils/time_calculator.dart';

class AnalysisInfoCard extends StatelessWidget {
  const AnalysisInfoCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ScoreProvider>(
      builder: (context, provider, child) {
        if (provider.manualInput == null) {
          return const SizedBox.shrink();
        }

        final tempo = provider.currentTempo;
        final timeSignature = provider.currentTimeSignature;
        final pages = provider.currentPages;
        final totalMeasures = pages.fold<int>(0, (sum, page) => sum + page.measures);
        
        // 총 연주 시간 계산 (사용자 제공 공식 사용)
        final totalDuration = TimeCalculator.calculateTotalDuration(
          tempo,
          timeSignature,
          totalMeasures,
        );

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '악보 정보',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                _InfoRow(label: '템포', value: '$tempo BPM'),
                _InfoRow(label: '박자표', value: timeSignature),
                _InfoRow(label: '페이지 수', value: '${pages.length}'),
                _InfoRow(label: '총 마디 수', value: '$totalMeasures'),
                _InfoRow(
                  label: '예상 연주 시간',
                  value: '${totalDuration.toStringAsFixed(1)}초',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

