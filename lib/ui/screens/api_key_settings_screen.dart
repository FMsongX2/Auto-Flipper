import 'package:flutter/material.dart';
import '../../services/preferences_service.dart';
import '../../config/api_keys.dart';

class ApiKeySettingsScreen extends StatefulWidget {
  const ApiKeySettingsScreen({super.key});

  @override
  State<ApiKeySettingsScreen> createState() => _ApiKeySettingsScreenState();
}

class _ApiKeySettingsScreenState extends State<ApiKeySettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final PreferencesService _preferencesService = PreferencesService();
  bool _isLoading = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    // 우선순위: SharedPreferences > api_keys.dart 파일
    String? apiKey = await _preferencesService.getGeminiApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      apiKey = ApiKeys.getGeminiApiKey();
    }
    
    if (apiKey != null && mounted) {
      setState(() {
        _apiKeyController.text = apiKey!;
      });
    }
  }

  Future<void> _saveApiKey() async {
    if (_apiKeyController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API 키를 입력해주세요')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _preferencesService.saveGeminiApiKey(_apiKeyController.text);
      
      // 온디바이스 AI를 사용하므로 API 키 업데이트 불필요
      // (ML Kit은 API 키가 필요 없음)
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API 키가 저장되었습니다')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
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

  Future<void> _deleteApiKey() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API 키 삭제'),
        content: const Text(
          'API 키를 삭제하면 AI 분석 기능을 사용할 수 없습니다.\n'
          '이미지 스캐닝 또는 오디오 분석을 사용해야 합니다.\n\n'
          '삭제하시겠습니까?',
        ),
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
      await _preferencesService.saveGeminiApiKey(null);
      // 온디바이스 AI를 사용하므로 API 키 업데이트 불필요
      setState(() {
        _apiKeyController.clear();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API 키가 삭제되었습니다')),
        );
      }
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API 키 설정'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'API 키 정보',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Google Gemini API 키를 입력하면 AI 기반 악보 분석 기능을 사용할 수 있습니다.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'API 키가 없으면 이미지 스캐닝 또는 오디오 분석 기능을 사용할 수 있습니다.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        // API 키 발급 방법 안내 URL
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('API 키 발급 방법'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _apiKeyController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                labelText: 'Gemini API 키',
                hintText: 'AIza...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveApiKey,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('저장'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _apiKeyController.text.isEmpty ? null : _deleteApiKey,
              icon: const Icon(Icons.delete_outline),
              label: const Text('API 키 삭제'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.red,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.mic, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        const Text(
                          '대체 분석 방법',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• 이미지 스캐닝: 악보 이미지를 분석하여 템포와 마디 수를 추출합니다.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• 오디오 분석: 기기가 듣는 소리를 분석하여 실시간으로 페이지를 넘깁니다.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• 수동 입력: 각 페이지의 템포와 마디 수를 직접 입력할 수 있습니다.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

