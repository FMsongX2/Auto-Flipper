import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/analysis_result.dart';

enum TimerState { idle, running, paused }

class TimerProvider with ChangeNotifier {
  Timer? _mainPageTimer; // 메인 페이지 타이머
  Timer? _updateTimer; // UI 업데이트용 주기 타이머
  TimerState _state = TimerState.idle;
  int _currentPageIndex = 0;
  double _elapsedTime = 0.0; // 현재 페이지 경과 시간
  double _currentPageDuration = 0.0; // 현재 페이지 총 시간
  double _remainingTime = 0.0; // pause 시 남은 시간 저장
  bool _autoFlipEnabled = true;
  List<PageInfo>? _pages;
  
  // 콜백 함수
  Function(int)? onPageChanged;
  Future<void> Function()? onPageFlip;
  Function()? onTimerComplete;

  // Getters
  TimerState get state => _state;
  int get currentPageIndex => _currentPageIndex;
  double get elapsedSeconds => _elapsedTime;
  double get currentPageDuration => _currentPageDuration;
  double get remainingSeconds => (_currentPageDuration - _elapsedTime).clamp(0.0, _currentPageDuration);
  double get progress => _currentPageDuration > 0 
      ? (_elapsedTime / _currentPageDuration).clamp(0.0, 1.0)
      : 0.0;
  bool get autoFlipEnabled => _autoFlipEnabled;
  
  // 타이머 시작 (트리거 역할)
  void start({
    required List<PageInfo> pages,
    required int startPageIndex,
    bool autoFlip = true,
  }) {
    if (pages.isEmpty) {
      debugPrint('TimerProvider: start - pages is empty, aborting');
      return;
    }
    
    debugPrint('TimerProvider: start - pages count: ${pages.length}, startPageIndex: $startPageIndex, autoFlip: $autoFlip');
    debugPrint('TimerProvider: start - onPageFlip is ${onPageFlip != null ? "set" : "null"}');
    debugPrint('TimerProvider: start - onPageChanged is ${onPageChanged != null ? "set" : "null"}');
    
    _pages = pages;
    _currentPageIndex = startPageIndex.clamp(0, pages.length - 1);
    _autoFlipEnabled = autoFlip;
    _state = TimerState.running;
    
    debugPrint('TimerProvider: start - starting timer for page index: $_currentPageIndex');
    
    // 🔥 CRITICAL: 배터리 최적화 방지 - _runTimerForPage 직전에 Wakelock 활성화
    // 갤럭시 탭 등 삼성 기기에서 타이머가 멈추는 것을 방지
    // TODO.md 요구사항: start() 함수에서 _runTimerForPage(_currentPageIndex) 직전에 Wakelock.enable()
    try {
      WakelockPlus.enable();
      debugPrint('TimerProvider: start - Wakelock enabled');
    } catch (e) {
      debugPrint('TimerProvider: start - Failed to enable wakelock: $e');
    }
    
    // 재귀 타이머 시작
    _runTimerForPage(_currentPageIndex);
    notifyListeners();
  }

  // 재귀 타이머 함수 (핵심 로직)
  void _runTimerForPage(int pageIndex) {
    if (_pages == null || _pages!.isEmpty) return;
    
    // 종료 조건: 모든 페이지가 완료된 경우
    if (pageIndex >= _pages!.length) {
      stop();
      onTimerComplete?.call();
      return;
    }
    
    // 현재 페이지 시간 설정
    final currentPage = _pages![pageIndex];
    _currentPageDuration = currentPage.durationSeconds ?? 0.0;
    _elapsedTime = 0.0; // 페이지가 바뀌었으므로 카운트다운 초기화
    _currentPageIndex = pageIndex;
    
    // 페이지 시간이 0이면 즉시 다음 페이지로
    if (_currentPageDuration <= 0) {
      _moveToNextPageAndContinue();
      return;
    }
    
    notifyListeners();
    
    // UI 업데이트용 주기 타이머 시작 (100ms 간격)
    _startUpdateTimer();
    
    // 메인 페이지 타이머 시작
    _mainPageTimer?.cancel();
    final durationMs = (_currentPageDuration * 1000).round();
    debugPrint('TimerProvider: _runTimerForPage - starting timer for page $pageIndex, duration: ${_currentPageDuration}s (${durationMs}ms)');
    
    _mainPageTimer = Timer(Duration(milliseconds: durationMs), () {
      // ----- 메인 타이머 콜백 (시간 만료 시) ----- //
      
      debugPrint('TimerProvider: _mainPageTimer callback - page $pageIndex timer expired');
      
      _updateTimer?.cancel(); // UI 타이머 중지
      _elapsedTime = _currentPageDuration; // 경과 시간을 완료 상태로 설정
      
      int nextPageIndex = pageIndex + 1;
      
      debugPrint('TimerProvider: _mainPageTimer callback - nextPageIndex: $nextPageIndex, total pages: ${_pages!.length}');
      
      // 마지막 페이지를 넘었으면 종료
      if (nextPageIndex >= _pages!.length) {
        debugPrint('TimerProvider: _mainPageTimer callback - reached end, stopping');
        stop();
        onTimerComplete?.call();
        return;
      }
      
      // 자동 넘김이 활성화되어 있으면 페이지 넘김
      if (_autoFlipEnabled) {
        debugPrint('TimerProvider: _mainPageTimer callback - autoFlip enabled, calling _performPageFlipAndContinue');
        // 실제 뷰어 페이지 넘김 (비동기 처리)
        // _currentPageIndex는 _performPageFlipAndContinue 내부에서 설정됨
        _performPageFlipAndContinue(nextPageIndex);
      } else {
        debugPrint('TimerProvider: _mainPageTimer callback - autoFlip disabled, pausing');
        // 자동 넘김이 꺼져있으면 일시정지
        pause();
        onTimerComplete?.call();
      }
      
      // ------------------------------------ //
    });
  }

  // 페이지 넘김 및 다음 타이머 시작 (비동기 처리)
  Future<void> _performPageFlipAndContinue(int nextPageIndex) async {
    debugPrint('TimerProvider: _performPageFlipAndContinue - called with nextPageIndex: $nextPageIndex');
    
    // 상태가 여전히 running인지 확인 (pause되지 않았는지)
    if (_state != TimerState.running) {
      debugPrint('TimerProvider: _performPageFlipAndContinue - state is not running ($_state), aborting');
      return; // 상태가 변경되었으면 중단
    }
    
    // 현재 페이지 인덱스 업데이트 (페이지 넘김 전에)
    _currentPageIndex = nextPageIndex;
    debugPrint('TimerProvider: _performPageFlipAndContinue - _currentPageIndex updated to: $_currentPageIndex');
    
    // 페이지 변경 콜백 호출 (뷰어 동기화를 위해 먼저 호출)
    if (onPageChanged != null) {
      debugPrint('TimerProvider: _performPageFlipAndContinue - calling onPageChanged($nextPageIndex)');
      onPageChanged!.call(nextPageIndex);
    } else {
      debugPrint('TimerProvider: _performPageFlipAndContinue - onPageChanged is null!');
    }
    
    // 페이지 넘김 콜백 호출 (실제 뷰어 페이지 넘김)
    if (onPageFlip != null) {
      debugPrint('TimerProvider: _performPageFlipAndContinue - calling onPageFlip()');
      try {
        // 🔥 CRITICAL: onPageFlip 콜백을 강제로 실행
        // 갤럭시 탭 S10+에서도 작동하도록 명시적으로 호출
        await onPageFlip!();
        debugPrint('TimerProvider: _performPageFlipAndContinue - onPageFlip() completed');
        
        // 애니메이션 완료 대기 (특정 기기에서 필요할 수 있음)
        await Future.delayed(const Duration(milliseconds: 300));
        
        // 페이지 넘김이 완료되었는지 확인
        debugPrint('TimerProvider: _performPageFlipAndContinue - Page flip delay completed, currentPageIndex: $_currentPageIndex');
      } catch (e, stackTrace) {
        debugPrint('TimerProvider: _performPageFlipAndContinue - Page flip error: $e');
        debugPrint('TimerProvider: _performPageFlipAndContinue - Stack trace: $stackTrace');
        
        // 에러가 발생해도 재시도
        debugPrint('TimerProvider: _performPageFlipAndContinue - Retrying onPageFlip() after error');
        try {
          await Future.delayed(const Duration(milliseconds: 500));
          if (onPageFlip != null && _state == TimerState.running) {
            await onPageFlip!();
            debugPrint('TimerProvider: _performPageFlipAndContinue - Retry successful');
          }
        } catch (retryError) {
          debugPrint('TimerProvider: _performPageFlipAndContinue - Retry also failed: $retryError');
          // 에러가 발생해도 계속 진행 (다음 페이지 타이머는 계속 실행됨)
        }
      }
    } else {
      debugPrint('TimerProvider: _performPageFlipAndContinue - ERROR: onPageFlip is null! Page flip will not occur!');
      debugPrint('TimerProvider: _performPageFlipAndContinue - This is a CRITICAL error - callback must be set!');
    }
    
    // 상태가 여전히 running인지 다시 확인 (pause되지 않았는지)
    if (_state == TimerState.running) {
      debugPrint('TimerProvider: _performPageFlipAndContinue - state is still running, calling _runTimerForPage($nextPageIndex)');
      // [TODO 6-5] 가장 중요: onPageFlip 이후, _runTimerForPage(nextPageIndex)를 재귀 호출하여 다음 페이지 타이머를 시작
      _runTimerForPage(nextPageIndex);
      notifyListeners();
    } else {
      debugPrint('TimerProvider: _performPageFlipAndContinue - state changed during page flip ($_state), stopping');
    }
  }

  // UI 업데이트용 주기 타이머 (오직 UI 갱신만 담당)
  void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_state == TimerState.running) {
        _elapsedTime += 0.1;
        
        // UI 갱신만 수행 (타이머 중지 로직은 제거)
        // 타이머 중지는 오직 _mainPageTimer 콜백, pause(), stop()에서만 처리
        notifyListeners();
      } else {
        // paused 상태면 타이머 중지
        timer.cancel();
      }
    });
  }

  // 일시정지 (남은 시간 저장)
  void pause() {
    if (_state == TimerState.running) {
      _state = TimerState.paused;
      
      // 🔥 CRITICAL: Wakelock 비활성화 (일시정지 시 배터리 절약)
      // TODO.md 요구사항: pause() 함수에서 _state = TimerState.paused 직후에 Wakelock.disable()
      try {
        WakelockPlus.disable();
        debugPrint('TimerProvider: pause - Wakelock disabled');
      } catch (e) {
        debugPrint('TimerProvider: pause - Failed to disable wakelock: $e');
      }
      
      // 메인 타이머와 UI 타이머 모두 취소
      _mainPageTimer?.cancel();
      _updateTimer?.cancel();
      
      // 현재 페이지의 남은 시간 계산 및 저장
      _remainingTime = (_currentPageDuration - _elapsedTime).clamp(0.0, _currentPageDuration);
      
      notifyListeners();
    }
  }

  // 재개 (남은 시간으로 타이머 재시작, 재귀 구조 유지)
  void resume() {
    if (_state == TimerState.paused && _pages != null && _pages!.isNotEmpty) {
      _state = TimerState.running;
      
      // 🔥 CRITICAL: 배터리 최적화 방지 - 화면이 꺼지지 않도록 Wakelock 활성화
      // TODO.md 요구사항: resume() 함수에서 _state = TimerState.running 직후에 Wakelock.enable()
      try {
        WakelockPlus.enable();
        debugPrint('TimerProvider: resume - Wakelock enabled');
      } catch (e) {
        debugPrint('TimerProvider: resume - Failed to enable wakelock: $e');
      }
      
      // 남은 시간이 0 이하면 현재 페이지 타이머 재시작
      if (_remainingTime <= 0) {
        // 🚨 _moveToNextPageAndContinue() 호출 삭제!
        // 현재 페이지의 타이머를 그냥 시작하면 됨
        _runTimerForPage(_currentPageIndex);
        return;
      }
      
      // 남은 시간으로 타이머 재시작
      _elapsedTime = _currentPageDuration - _remainingTime;
      
      // UI 업데이트용 주기 타이머 시작
      _startUpdateTimer();
      
      // 남은 시간으로 메인 타이머 시작
      _mainPageTimer?.cancel();
      _mainPageTimer = Timer(Duration(milliseconds: (_remainingTime * 1000).round()), () {
        // 타이머 콜백 (시간 만료 시)
        _updateTimer?.cancel();
        
        int nextPageIndex = _currentPageIndex + 1;
        
        // 마지막 페이지를 넘었으면 종료
        if (nextPageIndex >= _pages!.length) {
          stop();
          onTimerComplete?.call();
          return;
        }
        
        // 실제 뷰어 페이지 넘김 및 다음 타이머 시작 (재귀 구조 유지)
        _performPageFlipAndContinue(nextPageIndex);
      });
      
      notifyListeners();
    }
  }

  // 다음 페이지로 이동하고 타이머 계속 (레거시 호환용)
  Future<void> _moveToNextPageAndContinue() async {
    if (_pages == null || _pages!.isEmpty) return;
    
    int nextPageIndex = _currentPageIndex + 1;
    
    if (nextPageIndex >= _pages!.length) {
      stop();
      onTimerComplete?.call();
      return;
    }
    
    await _performPageFlipAndContinue(nextPageIndex);
  }

  // 정지 및 초기화
  void stop() {
    _mainPageTimer?.cancel();
    _updateTimer?.cancel();
    _state = TimerState.idle;
    
    // 🔥 CRITICAL: Wakelock 비활성화 (정지 시 배터리 절약)
    // TODO.md 요구사항: stop() 함수에서 _state = TimerState.idle 직후에 Wakelock.disable()
    try {
      WakelockPlus.disable();
      debugPrint('TimerProvider: stop - Wakelock disabled');
    } catch (e) {
      debugPrint('TimerProvider: stop - Failed to disable wakelock: $e');
    }
    
    _currentPageIndex = 0;
    _elapsedTime = 0.0;
    _currentPageDuration = 0.0;
    _remainingTime = 0.0;
    _pages = null;
    notifyListeners();
  }

  // 자동 넘김 토글
  void setAutoFlip(bool enabled) {
    _autoFlipEnabled = enabled;
    notifyListeners();
  }

  // 특정 페이지로 이동
  void goToPage(int pageIndex) {
    if (_pages == null || pageIndex < 0 || pageIndex >= _pages!.length) return;
    
    // 1. 현재 상태 저장
    final TimerState originalState = _state;
    
    // 현재 타이머 취소
    _mainPageTimer?.cancel();
    _updateTimer?.cancel();
    
    _currentPageIndex = pageIndex;
    _elapsedTime = 0.0;
    _remainingTime = 0.0;
    onPageChanged?.call(pageIndex);
    
    // 2. 원래 상태에 따라 처리
    if (originalState == TimerState.running) {
      // 실행 중이었으면 새 페이지에서 즉시 재시작
      _runTimerForPage(pageIndex);
    } else if (originalState == TimerState.paused) {
      // 일시정지 중이었으면, 상태만 paused로 복구
      _state = TimerState.paused;
    }
    // (originalState가 idle이었으면, _state는 idle로 유지됨)
    
    notifyListeners();
  }

  @override
  void dispose() {
    _mainPageTimer?.cancel();
    _updateTimer?.cancel();
    
    // 🔥 CRITICAL: dispose 시 Wakelock 비활성화 (메모리 누수 방지)
    // TODO.md 요구사항: dispose() 함수에서 super.dispose() 직전에 Wakelock.disable()
    try {
      WakelockPlus.disable();
      debugPrint('TimerProvider: dispose - Wakelock disabled');
    } catch (e) {
      debugPrint('TimerProvider: dispose - Failed to disable wakelock: $e');
    }
    
    super.dispose();
  }
}
