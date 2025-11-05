class ManualInput {
  final int tempo; // 30-300
  final String timeSignature; // "4/4" | "3/4" | "6/8" | "2/4"
  final List<PageInput> pages;

  ManualInput({
    required this.tempo,
    required this.timeSignature,
    required this.pages,
  });

  factory ManualInput.fromJson(Map<String, dynamic> json) {
    return ManualInput(
      tempo: json['tempo'] as int,
      timeSignature: json['timeSignature'] as String,
      pages: (json['pages'] as List)
          .map((page) => PageInput.fromJson(page as Map<String, dynamic>))
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

class PageInput {
  final int page; // 1부터 시작
  final int measures; // 0-200
  final double? durationSeconds; // 직접 설정한 연주시간 (초)
  final bool repeat; // 반복 여부

  PageInput({
    required this.page,
    required this.measures,
    this.durationSeconds,
    this.repeat = false,
  });

  factory PageInput.fromJson(Map<String, dynamic> json) {
    return PageInput(
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
  
  PageInput copyWith({
    int? page,
    int? measures,
    double? durationSeconds,
    bool? repeat,
  }) {
    return PageInput(
      page: page ?? this.page,
      measures: measures ?? this.measures,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      repeat: repeat ?? this.repeat,
    );
  }
}

