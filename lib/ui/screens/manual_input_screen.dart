import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/score_provider.dart';
import '../../models/manual_input.dart';
import '../../utils/time_calculator.dart';

class ManualInputScreen extends StatefulWidget {
  const ManualInputScreen({super.key});

  @override
  State<ManualInputScreen> createState() => _ManualInputScreenState();
}

class _ManualInputScreenState extends State<ManualInputScreen> {
  final TextEditingController _totalDurationController = TextEditingController();
  bool _useDurationMode = false;  // 예상 연주 시간 모드 여부

  @override
  void dispose() {
    _totalDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('수동 입력'),
      ),
      body: Consumer<ScoreProvider>(
        builder: (context, provider, child) {
          final manualInput = provider.manualInput;
          
          if (manualInput == null) {
            return const Center(
              child: Text('먼저 악보 파일을 선택하세요'),
            );
          }

          // 총 마디 수 계산
          final totalMeasures = manualInput.pages.fold<int>(
            0,
            (sum, page) => sum + page.measures,
          );
          
          // 예상 연주 시간 계산
          final calculatedDuration = TimeCalculator.calculateTotalDuration(
            manualInput.tempo,
            manualInput.timeSignature,
            totalMeasures,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // BPM 입력
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '템포 (BPM)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'BPM (30-300)',
                                  border: const OutlineInputBorder(),
                                  errorText: manualInput.tempo < 30 || manualInput.tempo > 300
                                      ? '30-300 범위의 값을 입력하세요'
                                      : null,
                                ),
                                controller: TextEditingController(
                                  text: manualInput.tempo.toString(),
                                )..selection = TextSelection.collapsed(
                                    offset: manualInput.tempo.toString().length,
                                  ),
                                onChanged: (value) {
                                  final tempo = int.tryParse(value);
                                  if (tempo != null && tempo >= 30 && tempo <= 300) {
                                    provider.updateTempo(tempo);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (manualInput.tempo > 30) {
                                  provider.updateTempo(manualInput.tempo - 1);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                if (manualInput.tempo < 300) {
                                  provider.updateTempo(manualInput.tempo + 1);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 예상 연주 시간 계산 결과 표시
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '예상 연주 시간',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${calculatedDuration.toStringAsFixed(1)}초 (${(calculatedDuration / 60).toStringAsFixed(1)}분)',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          '총 마디 수: $totalMeasures',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 모드 전환 (BPM/마디 수 입력 vs 예상 연주 시간 입력)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '입력 모드',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('BPM/마디 수 입력'),
                            Switch(
                              value: _useDurationMode,
                              onChanged: (value) {
                                setState(() {
                                  _useDurationMode = value;
                                });
                              },
                            ),
                            const Text('예상 연주 시간 입력'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 예상 연주 시간 입력 모드
                if (_useDurationMode) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '예상 연주 시간 입력',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _totalDurationController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: '연주 시간 (초)',
                              border: OutlineInputBorder(),
                              hintText: '예: 120.5',
                              helperText: '입력하면 자동으로 마디 수가 계산됩니다',
                            ),
                            onChanged: (value) {
                              final duration = double.tryParse(value);
                              if (duration != null && duration > 0) {
                                // 마디 수 자동 계산
                                final calculatedMeasures = TimeCalculator.calculateMeasuresFromDuration(
                                  manualInput.tempo,
                                  manualInput.timeSignature,
                                  duration,
                                );
                                
                                // 페이지당 44마디로 나누어 페이지 수 계산
                                final totalPages = (calculatedMeasures / 44.0).ceil();
                                
                                // 페이지 데이터 업데이트
                                final newPages = List.generate(
                                  totalPages,
                                  (index) {
                                    final pageNumber = index + 1;
                                    final isLastPage = index == totalPages - 1;
                                    final measuresForPage = isLastPage
                                        ? calculatedMeasures - (index * 44)
                                        : 44;
                                    
                                    return PageInput(
                                      page: pageNumber,
                                      measures: measuresForPage,
                                      repeat: false,
                                    );
                                  },
                                );
                                
                                // Provider에 업데이트
                                provider.updateManualInput(ManualInput(
                                  tempo: manualInput.tempo,
                                  timeSignature: manualInput.timeSignature,
                                  pages: newPages,
                                ));
                              }
                            },
                          ),
                          if (totalMeasures > 0) ...[
                            const SizedBox(height: 8),
                            Text(
                              '계산된 총 마디 수: $totalMeasures',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // 박자표 선택
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '박자표',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: manualInput.timeSignature,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: '4/4', child: Text('4/4')),
                            DropdownMenuItem(value: '3/4', child: Text('3/4')),
                            DropdownMenuItem(value: '6/8', child: Text('6/8')),
                            DropdownMenuItem(value: '2/4', child: Text('2/4')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              provider.updateTimeSignature(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                // BPM/마디 수 입력 모드일 때만 페이지별 마디 수 입력 표시
                if (!_useDurationMode) ...[
                  const SizedBox(height: 16),
                  
                  // 페이지별 마디 수
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '페이지별 마디 수',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => provider.addPage(),
                                tooltip: '페이지 추가',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...manualInput.pages.map((page) => _PageInputTile(
                            page: page,
                            tempo: manualInput.tempo,
                            timeSignature: manualInput.timeSignature,
                            onUpdate: (measures, repeat, durationSeconds) {
                              provider.updatePage(page.page, measures, repeat, durationSeconds: durationSeconds);
                            },
                            onDelete: manualInput.pages.length > 1
                                ? () => provider.removePage(page.page)
                                : null,
                          )),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PageInputTile extends StatefulWidget {
  final PageInput page;
  final int tempo;
  final String timeSignature;
  final Function(int, bool, double?) onUpdate;
  final VoidCallback? onDelete;

  const _PageInputTile({
    required this.page,
    required this.tempo,
    required this.timeSignature,
    required this.onUpdate,
    this.onDelete,
  });

  @override
  State<_PageInputTile> createState() => _PageInputTileState();
}

class _PageInputTileState extends State<_PageInputTile> {
  late TextEditingController _measuresController;
  late TextEditingController _durationController;
  bool _useCustomDuration = false;

  @override
  void initState() {
    super.initState();
    _measuresController = TextEditingController(text: widget.page.measures.toString());
    // 계산된 연주시간 또는 직접 설정한 연주시간
    final calculatedDuration = TimeCalculator.calculatePageDuration(
      widget.tempo,
      widget.timeSignature,
      widget.page.measures,
      widget.page.repeat,
    );
    final displayDuration = widget.page.durationSeconds ?? calculatedDuration;
    _durationController = TextEditingController(text: displayDuration.toStringAsFixed(1));
    _useCustomDuration = widget.page.durationSeconds != null;
  }

  @override
  void dispose() {
    _measuresController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _updateValues() {
    final measures = int.tryParse(_measuresController.text) ?? 0;
    final durationText = _durationController.text.trim();
    double? durationSeconds;
    
    if (_useCustomDuration && durationText.isNotEmpty) {
      durationSeconds = double.tryParse(durationText);
    }
    
    widget.onUpdate(measures, widget.page.repeat, durationSeconds);
  }

  @override
  Widget build(BuildContext context) {
    // 계산된 연주시간
    final calculatedDuration = TimeCalculator.calculatePageDuration(
      widget.tempo,
      widget.timeSignature,
      int.tryParse(_measuresController.text) ?? widget.page.measures,
      widget.page.repeat,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text('페이지 ${widget.page.page}'),
        subtitle: Text(
          '마디: ${widget.page.measures} | '
          '연주시간: ${(_useCustomDuration && widget.page.durationSeconds != null) 
              ? widget.page.durationSeconds!.toStringAsFixed(1) 
              : calculatedDuration.toStringAsFixed(1)}초',
        ),
        trailing: widget.onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: widget.onDelete,
                tooltip: '삭제',
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 마디 수 입력
                TextField(
                  controller: _measuresController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '마디 수 (0-200)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final measures = int.tryParse(value) ?? 0;
                    if (measures >= 0 && measures <= 200) {
                      // 마디 수가 변경되면 계산된 연주시간 업데이트
                      final newDuration = TimeCalculator.calculatePageDuration(
                        widget.tempo,
                        widget.timeSignature,
                        measures,
                        widget.page.repeat,
                      );
                      if (!_useCustomDuration) {
                        _durationController.text = newDuration.toStringAsFixed(1);
                      }
                      _updateValues();
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // 연주시간 직접 설정 토글
                Row(
                  children: [
                    const Text('연주시간 직접 설정'),
                    Switch(
                      value: _useCustomDuration,
                      onChanged: (value) {
                        setState(() {
                          _useCustomDuration = value;
                          if (!value) {
                            // 직접 설정 해제 시 계산된 시간으로 복원
                            final measures = int.tryParse(_measuresController.text) ?? widget.page.measures;
                            final calculated = TimeCalculator.calculatePageDuration(
                              widget.tempo,
                              widget.timeSignature,
                              measures,
                              widget.page.repeat,
                            );
                            _durationController.text = calculated.toStringAsFixed(1);
                            _updateValues();
                          }
                        });
                      },
                    ),
                  ],
                ),
                
                // 연주시간 입력 필드
                TextField(
                  controller: _durationController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  enabled: _useCustomDuration,
                  decoration: InputDecoration(
                    labelText: '연주시간 (초)',
                    border: const OutlineInputBorder(),
                    helperText: _useCustomDuration 
                        ? '직접 설정한 시간이 사용됩니다'
                        : '계산된 시간: ${calculatedDuration.toStringAsFixed(1)}초',
                  ),
                  onChanged: (value) {
                    if (_useCustomDuration) {
                      _updateValues();
                    }
                  },
                ),
                
                const SizedBox(height: 16),
                
                // 도돌이표
                Row(
                  children: [
                    const Text('도돌이표'),
                    Switch(
                      value: widget.page.repeat,
                      onChanged: (value) {
                        widget.onUpdate(
                          int.tryParse(_measuresController.text) ?? widget.page.measures,
                          value,
                          _useCustomDuration ? double.tryParse(_durationController.text) : null,
                        );
                      },
                    ),
                  ],
                ),
                
                // 삭제 버튼
                if (widget.onDelete != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('페이지 삭제', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

