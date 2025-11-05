import 'analysis_result.dart';
import 'manual_input.dart';
import 'score_type.dart';

class ScoreItem {
  final String id;
  final String folderId;
  final String name;
  final List<String> filePaths; // 파일 경로 리스트 (다중 이미지 지원)
  final ScoreType type; // 파일 타입 (pdf 또는 image)
  final String? thumbnailPath; // 미리보기 이미지 경로
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAccessedAt;
  final AnalysisResult? analysisResult;
  final ManualInput? manualInput;
  final bool useAI; // true: AI 분석, false: 수동 입력

  // 하위 호환성을 위한 getter (첫 번째 파일 경로 반환)
  String get filePath => filePaths.isNotEmpty ? filePaths.first : '';

  ScoreItem({
    required this.id,
    required this.folderId,
    required this.name,
    required this.filePaths,
    required this.type,
    this.thumbnailPath,
    required this.createdAt,
    required this.updatedAt,
    this.lastAccessedAt,
    this.analysisResult,
    this.manualInput,
    this.useAI = true,
  });

  factory ScoreItem.fromJson(Map<String, dynamic> json) {
    // 하위 호환성: 기존 filePath가 있으면 리스트로 변환
    List<String> filePaths;
    if (json['filePaths'] != null) {
      filePaths = (json['filePaths'] as List).map((e) => e as String).toList();
    } else if (json['filePath'] != null) {
      // 기존 형식 지원
      filePaths = [json['filePath'] as String];
    } else {
      filePaths = [];
    }

    // 하위 호환성: type이 없으면 filePath에서 추론
    ScoreType type;
    if (json['type'] != null) {
      type = ScoreType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => filePaths.isNotEmpty && filePaths.first.toLowerCase().endsWith('.pdf')
            ? ScoreType.pdf
            : ScoreType.image,
      );
    } else {
      // 기존 형식: filePath에서 추론
      type = filePaths.isNotEmpty && filePaths.first.toLowerCase().endsWith('.pdf')
          ? ScoreType.pdf
          : ScoreType.image;
    }

    return ScoreItem(
      id: json['id'] as String,
      folderId: json['folderId'] as String,
      name: json['name'] as String,
      filePaths: filePaths,
      type: type,
      thumbnailPath: json['thumbnailPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.parse(json['lastAccessedAt'] as String)
          : null,
      analysisResult: json['analysisResult'] != null
          ? AnalysisResult.fromJson(json['analysisResult'] as Map<String, dynamic>)
          : null,
      manualInput: json['manualInput'] != null
          ? ManualInput.fromJson(json['manualInput'] as Map<String, dynamic>)
          : null,
      useAI: json['useAI'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'folderId': folderId,
      'name': name,
      'filePaths': filePaths,
      'type': type.toString(),
      'thumbnailPath': thumbnailPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
      'analysisResult': analysisResult?.toJson(),
      'manualInput': manualInput?.toJson(),
      'useAI': useAI,
    };
  }

  ScoreItem copyWith({
    String? id,
    String? folderId,
    String? name,
    List<String>? filePaths,
    ScoreType? type,
    String? thumbnailPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastAccessedAt,
    AnalysisResult? analysisResult,
    ManualInput? manualInput,
    bool? useAI,
  }) {
    return ScoreItem(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      name: name ?? this.name,
      filePaths: filePaths ?? this.filePaths,
      type: type ?? this.type,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      analysisResult: analysisResult ?? this.analysisResult,
      manualInput: manualInput ?? this.manualInput,
      useAI: useAI ?? this.useAI,
    );
  }
}

