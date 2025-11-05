class AnalysisResult {
  final int tempo; // 30-300
  final String? timeSignature; // "4/4" | "3/4" | "6/8" | "2/4" | null
  final List<PageInfo> pages;

  AnalysisResult({
    required this.tempo,
    this.timeSignature,
    required this.pages,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      tempo: json['tempo'] as int,
      timeSignature: json['timeSignature'] as String?,
      pages: (json['pages'] as List)
          .map((page) => PageInfo.fromJson(page as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tempo': tempo,
      'timeSignature': timeSignature,
      'pages': pages.map((page) => page.toJson()).toList(),
    };
  }
}

class PageInfo {
  final int page; // 1부터 시작
  final int measures; // 0 이상
  final double? durationSeconds; // 계산된 시간(초)
  final bool repeat; // 도돌이표 여부

  PageInfo({
    required this.page,
    required this.measures,
    this.durationSeconds,
    this.repeat = false,
  });

  factory PageInfo.fromJson(Map<String, dynamic> json) {
    return PageInfo(
      page: json['page'] as int,
      measures: json['measures'] as int,
      durationSeconds: json['durationSeconds'] != null
          ? (json['durationSeconds'] as num).toDouble()
          : null,
      repeat: json['repeat'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'measures': measures,
      'durationSeconds': durationSeconds,
      'repeat': repeat,
    };
  }
}

