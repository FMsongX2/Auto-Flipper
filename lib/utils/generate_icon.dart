import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// 앱 아이콘 생성 유틸리티
/// Flutter에서 실행하여 아이콘 이미지를 생성할 수 있습니다.
/// 
/// 사용법:
/// 1. flutter run -d windows (또는 다른 플랫폼)
/// 2. 또는 별도의 스크립트로 실행
/// 
/// 주의: 실제 앱 아이콘 생성은 flutter_launcher_icons 패키지를 사용하는 것이 권장됩니다.
Future<void> generateAppIcon() async {
  // 아이콘 크기 목록 (Android/iOS 표준 크기)
  final sizes = [
    48,   // mdpi
    72,   // hdpi
    96,   // xhdpi
    144,  // xxhdpi
    192,  // xxxhdpi
    512,  // Google Play Store
    1024, // App Store
  ];

  for (final size in sizes) {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    
    // 흰색 배경
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
        Radius.circular(size * 0.2),
      ),
      backgroundPaint,
    );

    // FA 로고 그리기
    canvas.save();
    canvas.translate(size / 2, size / 2);
    canvas.rotate(-0.15); // 약 -8.6도 기울임

    final textStyle = TextStyle(
      color: Colors.black,
      fontSize: size * 0.6,
      fontWeight: FontWeight.w900,
      letterSpacing: -size * 0.08,
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
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    
    canvas.restore();

    // 이미지로 변환
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      final file = File('app_icon_$size.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      debugPrint('Generated: ${file.path}');
    }
  }
  
  debugPrint('All icons generated successfully!');
}
