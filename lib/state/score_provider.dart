import 'package:flutter/widgets.dart';
import 'dart:io';
import '../models/manual_input.dart';
import '../models/analysis_result.dart';
import '../models/score_type.dart';
import '../services/preferences_service.dart';
import '../utils/time_calculator.dart';
import '../ui/widgets/score_viewer.dart';

class ScoreProvider with ChangeNotifier {
  final PreferencesService _preferencesService = PreferencesService();

  // 상태 변수
  List<File>? _selectedFiles;
  List<String>? _filePaths;
  ScoreType? _scoreType;
  ManualInput? _manualInput;
  int _currentPage = 0;
  GlobalKey<ScoreViewerState>? scoreViewerKey;

  // Getters
  List<File>? get selectedFiles => _selectedFiles;
  List<String>? get filePaths => _filePaths;
  ScoreType? get scoreType => _scoreType;
  File? get selectedFile => _selectedFiles?.isNotEmpty == true ? _selectedFiles![0] : null;
  String? get filePath => _filePaths?.isNotEmpty == true ? _filePaths![0] : null;
  ManualInput? get manualInput => _manualInput;
  int get currentPage => _currentPage;
  
  // Setters
  set selectedFiles(List<File>? files) {
    _selectedFiles = files;
    notifyListeners();
  }
  
  set filePaths(List<String>? paths) {
    _filePaths = paths;
    notifyListeners();
  }
  
  set scoreType(ScoreType? type) {
    _scoreType = type;
    notifyListeners();
  }
  
  set selectedFile(File? file) {
    _selectedFiles = file != null ? [file] : null;
    _filePaths = file != null ? [file.path] : null;
    notifyListeners();
  }
  
  set filePath(String? path) {
    _filePaths = path != null ? [path] : null;
    _selectedFiles = path != null ? [File(path)] : null;
    notifyListeners();
  }
  
  set manualInput(ManualInput? input) {
    _manualInput = input;
    notifyListeners();
  }

  // SSOT 원칙: _manualInput만 참조하는 getter들
  int get currentTempo {
    if (_manualInput != null) {
      return _manualInput!.tempo;
    }
    return 120; // 기본값
  }

  String get currentTimeSignature {
    if (_manualInput != null) {
      return _manualInput!.timeSignature;
    }
    return '4/4'; // 기본값
  }

  List<PageInfo> get currentPages {
    if (_manualInput != null) {
      final pages = _manualInput!.pages;
      final processedPages = <PageInfo>[];
      
      // 각 페이지를 순회하면서 measures가 0인 경우 직전 페이지의 measures를 사용
      for (int i = 0; i < pages.length; i++) {
        final p = pages[i];
        int measures = p.measures;
        
        // measures가 0이거나 설정되지 않은 경우
        if (measures == 0) {
          if (i == 0) {
            // 첫 번째 페이지인 경우 기본값 사용 (16마디)
            measures = 16;
            debugPrint('ScoreProvider: currentPages - page ${p.page} has 0 measures, using default: 16');
          } else {
            // 직전 페이지의 measures 사용
            final previousMeasures = processedPages[i - 1].measures;
            measures = previousMeasures;
            debugPrint('ScoreProvider: currentPages - page ${p.page} has 0 measures, using previous page measures: $measures');
          }
        }
        
        // 직접 설정한 연주시간이 있으면 우선 사용, 없으면 계산
        final duration = p.durationSeconds ?? TimeCalculator.calculatePageDuration(
          _manualInput!.tempo,
          _manualInput!.timeSignature,
          measures,
          p.repeat,
        );
        
        processedPages.add(PageInfo(
          page: p.page,
          measures: measures,
          durationSeconds: duration,
          repeat: p.repeat,
        ));
      }
      
      return processedPages;
    }
    return [];
  }

  // 파일 선택 (다중 이미지 지원)
  Future<void> selectFilesAndAnalyze(List<File> files, ScoreType type) async {
    if (files.isEmpty) return;
    
    _selectedFiles = files;
    _filePaths = files.map((f) => f.path).toList();
    _scoreType = type;
    
    // 파일 경로 저장 (다중 이미지 지원)
    if (_filePaths!.isNotEmpty) {
      await _preferencesService.saveFilePaths(_filePaths!);
    }
    
    // 수동 입력 초기화 (기본값)
    // PDF면 1페이지, 이미지면 파일 개수만큼 페이지 생성
    final pageCount = type == ScoreType.pdf ? 1 : files.length;
    if (_manualInput == null) {
      _manualInput = ManualInput(
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
      await _preferencesService.saveManualInput(_manualInput!);
    }
    
    notifyListeners();
  }

  // 하위 호환성을 위한 단일 파일 선택
  Future<void> selectFileAndAnalyze(File file) async {
    final isPdf = file.path.toLowerCase().endsWith('.pdf');
    await selectFilesAndAnalyze([file], isPdf ? ScoreType.pdf : ScoreType.image);
  }

  // 수동 입력 업데이트
  void updateManualInput(ManualInput input) {
    _manualInput = input;
    _preferencesService.saveManualInput(input);
    notifyListeners();
  }

  // 앱 시작 시 저장된 데이터 복원
  Future<void> loadSavedData() async {
    final savedManualInput = await _preferencesService.loadManualInput();
    final savedCurrentPage = await _preferencesService.loadCurrentPage();
    final savedFilePaths = await _preferencesService.loadFilePaths();

    if (savedManualInput != null) {
      _manualInput = savedManualInput;
    }
    _currentPage = savedCurrentPage;
    if (savedFilePaths != null && savedFilePaths.isNotEmpty) {
      _filePaths = savedFilePaths;
      _selectedFiles = savedFilePaths.map((path) => File(path)).toList();
      // 파일 확장자로 타입 판단 (첫 번째 파일 기준)
      _scoreType = savedFilePaths[0].toLowerCase().endsWith('.pdf') 
          ? ScoreType.pdf 
          : ScoreType.image;
    }

    notifyListeners();
  }

  // BPM 업데이트
  void updateTempo(int tempo) {
    if (_manualInput != null) {
      _manualInput = ManualInput(
        tempo: tempo,
        timeSignature: _manualInput!.timeSignature,
        pages: _manualInput!.pages,
      );
      _preferencesService.saveManualInput(_manualInput!);
      notifyListeners();
    }
  }

  // 박자표 업데이트
  void updateTimeSignature(String timeSignature) {
    if (_manualInput != null) {
      _manualInput = ManualInput(
        tempo: _manualInput!.tempo,
        timeSignature: timeSignature,
        pages: _manualInput!.pages,
      );
      _preferencesService.saveManualInput(_manualInput!);
      notifyListeners();
    }
  }

  // 페이지 추가
  void addPage() {
    if (_manualInput != null) {
      final newPageNumber = _manualInput!.pages.isEmpty
          ? 1
          : _manualInput!.pages.map((p) => p.page).reduce((a, b) => a > b ? a : b) + 1;
      
      final newPages = List<PageInput>.from(_manualInput!.pages)
        ..add(PageInput(
          page: newPageNumber,
          measures: 16, // 기본값 16마디
          repeat: false,
        ));

      _manualInput = ManualInput(
        tempo: _manualInput!.tempo,
        timeSignature: _manualInput!.timeSignature,
        pages: newPages,
      );
      _preferencesService.saveManualInput(_manualInput!);
      notifyListeners();
    }
  }

  // 페이지 삭제
  void removePage(int pageNumber) {
    if (_manualInput != null && _manualInput!.pages.length > 1) {
      final newPages = _manualInput!.pages.where((p) => p.page != pageNumber).toList();
      // 페이지 번호 재정렬
      for (int i = 0; i < newPages.length; i++) {
        newPages[i] = PageInput(
          page: i + 1,
          measures: newPages[i].measures,
          durationSeconds: newPages[i].durationSeconds,
          repeat: newPages[i].repeat,
        );
      }

      _manualInput = ManualInput(
        tempo: _manualInput!.tempo,
        timeSignature: _manualInput!.timeSignature,
        pages: newPages,
      );
      _preferencesService.saveManualInput(_manualInput!);
      notifyListeners();
    }
  }

  // 페이지 업데이트
  void updatePage(int pageNumber, int measures, bool repeat, {double? durationSeconds}) {
    if (_manualInput != null) {
      final newPages = _manualInput!.pages.map((p) {
        if (p.page == pageNumber) {
          return PageInput(
            page: pageNumber,
            measures: measures,
            durationSeconds: durationSeconds,
            repeat: repeat,
          );
        }
        return p;
      }).toList();

      _manualInput = ManualInput(
        tempo: _manualInput!.tempo,
        timeSignature: _manualInput!.timeSignature,
        pages: newPages,
      );
      _preferencesService.saveManualInput(_manualInput!);
      notifyListeners();
    }
  }

  // 현재 페이지 업데이트
  void setCurrentPage(int page) {
    _currentPage = page;
    _preferencesService.saveCurrentPage(page);
    notifyListeners();
  }

  // 초기화
  void reset() {
    _selectedFiles = null;
    _filePaths = null;
    _scoreType = null;
    _manualInput = null;
    _currentPage = 0;
    notifyListeners();
  }
}
