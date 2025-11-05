import 'package:flutter/material.dart';

/// 기울어진 F와 A가 합쳐진 로고 위젯
/// 흰색 배경에 두꺼운 검은색 글자
class FALogo extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Color textColor;
  final double rotation; // 회전 각도 (라디안)

  const FALogo({
    super.key,
    this.size = 120,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.rotation = -0.15, // 약 -8.6도 기울임
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _FALogoPainter(
          textColor: textColor,
          rotation: rotation,
        ),
      ),
    );
  }
}

class _FALogoPainter extends CustomPainter {
  final Color textColor;
  final double rotation;

  _FALogoPainter({
    required this.textColor,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 캔버스 중심으로 이동
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotation);

    // 두꺼운 폰트로 "FA" 그리기
    final textStyle = TextStyle(
      color: textColor,
      fontSize: size.width * 0.6,
      fontWeight: FontWeight.w900, // 매우 두꺼운 폰트
      letterSpacing: -size.width * 0.08, // F와 A가 겹치도록 간격 조정
    );

    final textSpan = TextSpan(
      text: 'FA',
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();

    // 텍스트를 중앙에 배치
    final offset = Offset(
      -textPainter.width / 2,
      -textPainter.height / 2,
    );

    textPainter.paint(canvas, offset);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
