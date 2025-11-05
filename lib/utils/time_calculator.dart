class TimeCalculator {
  /// 박자표별 마디 시간 계산
  /// 
  /// [bpm] 템포 (30-300)
  /// [timeSignature] 박자표 (예: "4/4", "3/4")
  /// 
  /// 반환값: 마디당 시간(초)
  /// 공식: (240 / BPM) × (박자표 분자 / 4) = (60 / BPM) × 박자표 분자
  /// 4/4박자: (240 / BPM) = (60 / BPM) × 4
  static double calculateMeasureDuration(int bpm, String timeSignature) {
    // 박자표에서 분자 추출 (예: "4/4" -> 4, "3/4" -> 3)
    final parts = timeSignature.split('/');
    final numerator = int.tryParse(parts[0]) ?? 4;
    
    // 마디당 시간 = (60 / BPM) * 박자표 분자
    // 또는 4/4박자의 경우: (240 / BPM)
    // 예: 120BPM, 4/4 = (240/120) = 2초 또는 (60/120) * 4 = 2초
    return (60.0 / bpm) * numerator;
  }

  /// 총 연주 시간 계산 (사용자 제공 공식 사용)
  /// 
  /// [bpm] 템포 (1분당 4분음표의 수)
  /// [timeSignature] 박자표 (예: "4/4", "3/4", "6/8")
  /// [totalMeasures] 총 마디 수 (M)
  /// 
  /// 반환값: 총 연주 시간(초)
  /// 공식: (240 × X × M) / (BPM × Y)
  /// X: 박자표 분자, Y: 박자표 분모
  static double calculateTotalDuration(
    int bpm,
    String timeSignature,
    int totalMeasures,
  ) {
    final parts = timeSignature.split('/');
    final numerator = int.tryParse(parts[0]) ?? 4;  // X
    final denominator = parts.length > 1 ? (int.tryParse(parts[1]) ?? 4) : 4;  // Y
    
    // 공식: (240 × X × M) / (BPM × Y)
    return (240.0 * numerator * totalMeasures) / (bpm * denominator);
  }

  /// 페이지 연주 시간 계산
  /// 
  /// [bpm] 템포
  /// [timeSignature] 박자표
  /// [measures] 마디 수
  /// [repeat] 도돌이표 여부
  /// 
  /// 반환값: 페이지 연주 시간(초)
  static double calculatePageDuration(
    int bpm,
    String timeSignature,
    int measures,
    bool repeat,
  ) {
    final measureDuration = calculateMeasureDuration(bpm, timeSignature);
    final duration = measures * measureDuration;
    
    // 도돌이표가 있으면 2배
    return repeat ? duration * 2 : duration;
  }

  /// 예상 연주 시간으로부터 마디 수 계산
  /// 
  /// [bpm] 템포 (1분당 4분음표의 수)
  /// [timeSignature] 박자표
  /// [totalDurationSeconds] 총 연주 시간(초)
  /// 
  /// 반환값: 총 마디 수
  /// 공식 역산: M = (총 연주 시간 × BPM × Y) / (240 × X)
  static int calculateMeasuresFromDuration(
    int bpm,
    String timeSignature,
    double totalDurationSeconds,
  ) {
    final parts = timeSignature.split('/');
    final numerator = int.tryParse(parts[0]) ?? 4;  // X
    final denominator = parts.length > 1 ? (int.tryParse(parts[1]) ?? 4) : 4;  // Y
    
    // 공식 역산: M = (총 연주 시간 × BPM × Y) / (240 × X)
    return ((totalDurationSeconds * bpm * denominator) / (240.0 * numerator)).round();
  }
}

