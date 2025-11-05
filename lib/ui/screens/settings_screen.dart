import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../services/preferences_service.dart';
import '../../services/feedback_service.dart';
import '../../state/score_provider.dart';
import 'bookmarks_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PreferencesService _preferencesService = PreferencesService();
  late AppSettings _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _preferencesService.loadAppSettings();
    setState(() {
      _settings = settings;
      _isLoading = false;
      // 피드백 서비스에 설정 적용
      FeedbackService.setSoundEnabled(settings.soundFeedback);
      FeedbackService.setVibrationEnabled(settings.vibrationFeedback);
    });
  }

  Future<void> _saveSettings() async {
    await _preferencesService.saveAppSettings(_settings);
    // 피드백 서비스에 설정 적용
    FeedbackService.setSoundEnabled(_settings.soundFeedback);
    FeedbackService.setVibrationEnabled(_settings.vibrationFeedback);
  }

  void _updateSettings(AppSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 박자표 기본값
          Card(
            child: ListTile(
              title: const Text('박자표 기본값'),
              subtitle: Text(_settings.defaultTimeSignature),
              trailing: DropdownButton<String>(
                value: _settings.defaultTimeSignature,
                items: const [
                  DropdownMenuItem(value: '4/4', child: Text('4/4')),
                  DropdownMenuItem(value: '3/4', child: Text('3/4')),
                  DropdownMenuItem(value: '6/8', child: Text('6/8')),
                  DropdownMenuItem(value: '2/4', child: Text('2/4')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _updateSettings(_settings.copyWith(defaultTimeSignature: value));
                    // 수동 입력 모드에 반영
                    final provider = Provider.of<ScoreProvider>(context, listen: false);
                    if (provider.manualInput != null) {
                      provider.updateTimeSignature(value);
                    }
                  }
                },
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 애니메이션 효과
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('페이지 전환 애니메이션'),
                  subtitle: Text(
                    _settings.animationType == 'fade'
                        ? '페이드'
                        : _settings.animationType == 'slide'
                            ? '슬라이드'
                            : '없음',
                  ),
                  trailing: DropdownButton<String>(
                    value: _settings.animationType,
                    items: const [
                      DropdownMenuItem(value: 'fade', child: Text('페이드')),
                      DropdownMenuItem(value: 'slide', child: Text('슬라이드')),
                      DropdownMenuItem(value: 'none', child: Text('없음')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _updateSettings(_settings.copyWith(animationType: value));
                      }
                    },
                  ),
                ),
                if (_settings.animationType != 'none')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('애니메이션 시간: ${_settings.animationDuration}ms'),
                        Slider(
                          value: _settings.animationDuration.toDouble(),
                          min: 100,
                          max: 300,
                          divisions: 20,
                          label: '${_settings.animationDuration}ms',
                          onChanged: (value) {
                            _updateSettings(
                              _settings.copyWith(animationDuration: value.toInt()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 자동 넘김 기본값
          Card(
            child: SwitchListTile(
              title: const Text('자동 넘김 기본값'),
              subtitle: const Text('앱 시작 시 자동 넘김이 활성화됩니다'),
              value: _settings.defaultAutoFlip,
              onChanged: (value) {
                _updateSettings(_settings.copyWith(defaultAutoFlip: value));
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 피드백 옵션
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('소리 피드백'),
                  subtitle: const Text('페이지 넘김 시 소리 재생'),
                  value: _settings.soundFeedback,
                  onChanged: (value) {
                    _updateSettings(_settings.copyWith(soundFeedback: value));
                  },
                ),
                SwitchListTile(
                  title: const Text('진동 피드백'),
                  subtitle: const Text('페이지 넘김 시 진동'),
                  value: _settings.vibrationFeedback,
                  onChanged: (value) {
                    _updateSettings(_settings.copyWith(vibrationFeedback: value));
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 화면 회전 잠금
          Card(
            child: SwitchListTile(
              title: const Text('화면 회전 잠금'),
              subtitle: const Text('화면 회전을 고정합니다'),
              value: _settings.screenRotationLock,
              onChanged: (value) async {
                _updateSettings(_settings.copyWith(screenRotationLock: value));
                // 화면 회전 잠금 적용
                if (value) {
                  await SystemChrome.setPreferredOrientations([
                    MediaQuery.of(context).orientation == Orientation.portrait
                        ? DeviceOrientation.portraitUp
                        : DeviceOrientation.landscapeLeft,
                  ]);
                } else {
                  await SystemChrome.setPreferredOrientations([
                    DeviceOrientation.portraitUp,
                    DeviceOrientation.landscapeLeft,
                    DeviceOrientation.landscapeRight,
                  ]);
                }
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 카운트다운 표시
          Card(
            child: SwitchListTile(
              title: const Text('페이지 넘김 카운트다운'),
              subtitle: const Text('페이지 넘김 전 카운트다운을 표시합니다'),
              value: _settings.showCountdown,
              onChanged: (value) {
                _updateSettings(_settings.copyWith(showCountdown: value));
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 북마크
          Card(
            child: ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('북마크 관리'),
              subtitle: const Text('저장된 악보 북마크 보기'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BookmarksScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

