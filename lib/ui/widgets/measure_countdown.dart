import 'package:flutter/material.dart';
import 'dart:async';

/// 오른쪽 위에 표시되는 1마디 카운트다운 위젯 (4, 3, 2, 1)
/// 파란색 굵은 숫자로 표시되며, 숫자가 나타났다 사라지며 카운트다운
class MeasureCountdown extends StatefulWidget {
  final double measureDuration; // 1마디 시간 (초)
  final VoidCallback onComplete; // 카운트다운 완료 시 호출되는 콜백
  
  const MeasureCountdown({
    super.key,
    required this.measureDuration,
    required this.onComplete,
  });

  @override
  State<MeasureCountdown> createState() => _MeasureCountdownState();
}

class _MeasureCountdownState extends State<MeasureCountdown>
    with SingleTickerProviderStateMixin {
  int _currentNumber = 4; // 현재 표시할 숫자 (4, 3, 2, 1)
  Timer? _countdownTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    
    // 애니메이션 컨트롤러 초기화
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // 카운트다운 시작
    _startCountdown();
  }

  void _startCountdown() {
    // 1마디를 4개로 나누어 각 숫자를 표시
    final quarterDuration = widget.measureDuration / 4.0;
    
    _currentNumber = 4;
    _animationController.forward();
    
    _countdownTimer = Timer.periodic(
      Duration(milliseconds: (quarterDuration * 1000).round()),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        
        setState(() {
          _currentNumber--;
          
          // 숫자 변경 시 페이드 애니메이션
          _animationController.reset();
          _animationController.forward();
          
          if (_currentNumber <= 0) {
            // 카운트다운 완료 (1까지 표시된 후)
            timer.cancel();
            
            // 마지막 숫자(1)가 사라진 후 완료
            Future.delayed(Duration(milliseconds: (quarterDuration * 1000).round()), () {
              if (mounted) {
                setState(() {
                  _isComplete = true;
                });
                widget.onComplete();
              }
            });
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isComplete) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      top: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Text(
          '$_currentNumber',
          style: const TextStyle(
            fontSize: 64, // 굵은 숫자
            fontWeight: FontWeight.bold,
            color: Colors.blue, // 파란색
          ),
        ),
      ),
    );
  }
}

