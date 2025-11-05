import 'manual_input.dart';

class Bookmark {
  final String id; // UUID
  final String filePath; // 파일 경로
  final String fileName; // 파일명
  final ManualInput lastUsedSettings; // 마지막 사용 설정
  final int createdAt; // 타임스탬프
  final int lastAccessedAt; // 마지막 접근 시간

  Bookmark({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.lastUsedSettings,
    required this.createdAt,
    required this.lastAccessedAt,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String,
      lastUsedSettings: ManualInput.fromJson(json['lastUsedSettings'] as Map<String, dynamic>),
      createdAt: json['createdAt'] as int,
      lastAccessedAt: json['lastAccessedAt'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'fileName': fileName,
      'lastUsedSettings': lastUsedSettings.toJson(),
      'createdAt': createdAt,
      'lastAccessedAt': lastAccessedAt,
    };
  }

  Bookmark copyWith({
    String? id,
    String? filePath,
    String? fileName,
    ManualInput? lastUsedSettings,
    int? createdAt,
    int? lastAccessedAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      lastUsedSettings: lastUsedSettings ?? this.lastUsedSettings,
      createdAt: createdAt ?? this.createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    );
  }
}

